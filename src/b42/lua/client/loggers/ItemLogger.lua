--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISDropWorldItemAction"
require "TimedActions/ISDropItemAction"
require "TimedActions/ISGrabItemAction"

local logger = ConsoleLogger and ConsoleLogger.new() or {
    Debug = function(msg) print("ConsoleLogger DEBUG: " .. tostring(msg)) end
}

-- hasPendingTransferActions checks the character's action queue.
local function hasPendingTransferActions(character)
    if not character then return false end

    local q = ISTimedActionQueue and ISTimedActionQueue.queues and ISTimedActionQueue.queues[character]
    if not q or not q.queue then return false end

    for i = 1, #q.queue do
        local act = q.queue[i]

        if act and (act.Type == "ISInventoryTransferAction" or act.Type == "ISDropItemAction" or act.Type == "ISDropWorldItemAction" or act.Type == "ISGrabItemAction") then
            return true
        end
    end

    return false
end

local ItemLogger = {
    buffer = {},
    hooked = false,
    OriginalFunctions = {},

    -- Debounce configuration
    DEBOUNCE_DELAY_MS = 350,  -- Pause after last item before flush (ms)
    MAX_HOLD_TIME_MS  = 3000, -- Force flush batch during extended looting (3s)
    MAX_BUFFER_SIZE   = 50,   -- Buffer entry limit

    lastItemTime = 0,
    firstItemTime = 0,
    isTickerActive = false
}

function ItemLogger.IsEnabledOnServer()
    return SandboxVars and SandboxVars.LogExtender and SandboxVars.LogExtender.ItemLogs
end

function ItemLogger.GetContainerName(container, character)
    if not container then return "container" end

    if character and container.isInCharacterInventory and container:isInCharacterInventory(character) then
        -- Distinguish between the main inventory and equipped bags/backpacks
        if container == character:getInventory() then
            return "inventory"
        end

        local bagItem = container.getContainingItem and container:getContainingItem()
        if bagItem and bagItem.getFullType then
            return "bag (" .. bagItem:getFullType() .. ")"
        end

        return "inventory"
    end

    local parent = container.getParent and container:getParent()
    if parent then
        if instanceof(parent, "IsoDeadBody") then
            return "corpse"
        end

        if instanceof(parent, "BaseVehicle") then
            local part = container.getVehiclePart and container:getVehiclePart()
            return part and ("vehicle:" .. tostring(part:getId())) or "vehicle"
        end

        if parent.getContainerName then
            local pName = parent:getContainerName()
            if pName and pName ~= "" and pName ~= "None" then
                return pName
            end
        end
    end

    local cType = container.getType and container:getType()
    if cType == "floor" then return "floor" end
    if cType and cType ~= "" and cType ~= "None" then return cType end

    return "container"
end

function ItemLogger.QueueItem(action, fullType, location)
    if not ItemLogger.IsEnabledOnServer() then return end
    if not fullType or fullType == "" then return end

    local now = getTimestampMs()
    if #ItemLogger.buffer == 0 then
        ItemLogger.firstItemTime = now
    end
    ItemLogger.lastItemTime = now

    table.insert(ItemLogger.buffer, {
        action = action,
        fullType = fullType,
        location = location or "unknown"
    })

    if #ItemLogger.buffer >= ItemLogger.MAX_BUFFER_SIZE then
        ItemLogger.FlushBuffer()
        return
    end

    -- Enable the ticker only when there is data in the buffer (Zero Idle Overhead)
    if not ItemLogger.isTickerActive then
        ItemLogger.isTickerActive = true
        Events.OnTick.Add(ItemLogger.OnTick)
    end
end

function ItemLogger.OnTick()
    if #ItemLogger.buffer == 0 then
        if ItemLogger.isTickerActive then
            ItemLogger.isTickerActive = false
            Events.OnTick.Remove(ItemLogger.OnTick)
        end
        return
    end

    local now = getTimestampMs()
    local character = getPlayer()

    -- Flush on timeout when looting hundreds of items
    if (now - ItemLogger.firstItemTime) >= ItemLogger.MAX_HOLD_TIME_MS then
        ItemLogger.FlushBuffer()
        return
    end

    -- Flush if the action queue is empty and 350 ms debounce elapsed
    local hasPending = hasPendingTransferActions(character)
    if not hasPending and (now - ItemLogger.lastItemTime) >= ItemLogger.DEBOUNCE_DELAY_MS then
        ItemLogger.FlushBuffer()
    end
end

function ItemLogger.FlushBuffer()
    if ItemLogger.isTickerActive then
        ItemLogger.isTickerActive = false
        Events.OnTick.Remove(ItemLogger.OnTick)
    end

    if #ItemLogger.buffer == 0 then return end

    local character = getPlayer()
    if not character then
        ItemLogger.buffer = {}
        return
    end

    local aggregated = {}
    local order = {}

    for _, entry in ipairs(ItemLogger.buffer) do
        local key = entry.action .. "|||" .. entry.fullType .. "|||" .. entry.location

        if not aggregated[key] then
            aggregated[key] = {
                action = entry.action,
                fullType = entry.fullType,
                location = entry.location,
                count = 1
            }
            table.insert(order, key)
        else
            aggregated[key].count = aggregated[key].count + 1
        end
    end

    ItemLogger.buffer = {}
    ItemLogger.firstItemTime = 0
    ItemLogger.lastItemTime = 0

    local lines = {}
    for _, key in ipairs(order) do
        local item = aggregated[key]
        local countStr = item.count > 1 and (tostring(item.count) .. "x ") or ""
        local prefix = logutils.GetLogLinePrefix(character, item.action)
        local msg = prefix .. " " .. countStr .. '"' .. item.fullType .. '" at ' .. item.location

        table.insert(lines, msg)
    end

    if #lines == 1 then
        sendClientCommand("LogExtender", "write", { mask = logutils.filemask.item, message = lines[1] })
    elseif #lines > 1 then
        sendClientCommand("LogExtender", "writeBatch", { mask = logutils.filemask.item, lines = lines })
    end
end

function ItemLogger.LogTransfer(character, item, srcContainer, destContainer)
    if not character or not character:isLocalPlayer() or not item then return end
    if srcContainer == destContainer then return end

    local srcName = ItemLogger.GetContainerName(srcContainer, character)
    local destName = ItemLogger.GetContainerName(destContainer, character)
    if srcName == destName then return end

    local location = logutils.GetLocation(character)
    local fullType = item:getFullType()

    local isSrcPlayer = srcName == "inventory" or srcName:find("^bag %(")
    local isDestPlayer = destName == "inventory" or destName:find("^bag %(")

    local action = nil
    if isSrcPlayer and destName == "floor" then
        action = "dropped on floor"
    elseif not isSrcPlayer and destName == "floor" then
        action = "dropped on floor from " .. srcName
    elseif srcName == "floor" and isDestPlayer then
        action = "taken from floor"
    elseif not isSrcPlayer and srcName ~= "floor" and isDestPlayer then
        action = "taken from " .. srcName
    elseif isSrcPlayer and destName ~= "floor" and not isDestPlayer then
        action = "put into " .. destName
    elseif isSrcPlayer and isDestPlayer then
        action = "moved from " .. srcName .. " to " .. destName
    else
        action = "transferred from " .. srcName .. " into " .. destName
    end

    if action then
        ItemLogger.QueueItem(action, fullType, location)
    end
end

function ItemLogger.OnInventoryTransferPerform(self)
    if ItemLogger.IsEnabledOnServer() and self.item then
        ItemLogger.LogTransfer(self.character, self.item, self.srcContainer, self.destContainer)
    end

    return ItemLogger.OriginalFunctions.ISInventoryTransferAction_perform(self)
end

function ItemLogger.OnDropItemPerform(self)
    if ItemLogger.IsEnabledOnServer() and self.character and self.character:isLocalPlayer() and self.item then
        local location = logutils.GetLocation(self.character)
        ItemLogger.QueueItem("dropped on floor", self.item:getFullType(), location)
    end

    return ItemLogger.OriginalFunctions.ISDropItemAction_perform(self)
end

function ItemLogger.OnDropWorldItemPerform(self)
    if ItemLogger.IsEnabledOnServer() and self.character and self.character:isLocalPlayer() and self.item then
        local location = self.sq and logutils.GetLocation(self.sq) or logutils.GetLocation(self.character)
        local fullType = self.item:getFullType()

        if self.isPlaceItem then
            local surfaceName = "surface"

            if self.sq then
                local objects = self.sq:getObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj.getContainerName and obj:getContainerName() and obj:getContainerName() ~= "" then
                            surfaceName = obj:getContainerName()
                            break
                        elseif obj and obj.getSprite and obj:getSprite() and obj:getSprite():getName() then
                            local sName = obj:getSprite():getName()
                            if sName:find("table") or sName:find("counter") or sName:find("desk") then
                                surfaceName = sName
                                break
                            end
                        end
                    end
                end
            end

            ItemLogger.QueueItem("placed on " .. surfaceName, fullType, location)
        else
            ItemLogger.QueueItem("dropped on floor", fullType, location)
        end
    end

    return ItemLogger.OriginalFunctions.ISDropWorldItemAction_perform(self)
end

function ItemLogger.OnGrabItemPerform(self)
    if ItemLogger.IsEnabledOnServer() and self.character and self.character:isLocalPlayer() and self.item then
        local worldItem = self.item -- In ISGrabItemAction it's IsoWorldInventoryObject
        local invItem = worldItem.getItem and worldItem:getItem() or worldItem
        if invItem and invItem.getFullType then
            local sq = worldItem.getSquare and worldItem:getSquare()
            local location = sq and logutils.GetLocation(sq) or logutils.GetLocation(self.character)
            ItemLogger.QueueItem("grabbed from world", invItem:getFullType(), location)
        end
    end

    return ItemLogger.OriginalFunctions.ISGrabItemAction_perform(self)
end

function ItemLogger.InitHooks()
    if ItemLogger.hooked then return end
    ItemLogger.hooked = true

    if ISInventoryTransferAction and ISInventoryTransferAction.perform then
        ItemLogger.OriginalFunctions.ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
        ISInventoryTransferAction.perform = ItemLogger.OnInventoryTransferPerform
    end

    if ISDropItemAction and ISDropItemAction.perform then
        ItemLogger.OriginalFunctions.ISDropItemAction_perform = ISDropItemAction.perform
        ISDropItemAction.perform = ItemLogger.OnDropItemPerform
    end

    if ISDropWorldItemAction and ISDropWorldItemAction.perform then
        ItemLogger.OriginalFunctions.ISDropWorldItemAction_perform = ISDropWorldItemAction.perform
        ISDropWorldItemAction.perform = ItemLogger.OnDropWorldItemPerform
    end

    if ISGrabItemAction and ISGrabItemAction.perform then
        ItemLogger.OriginalFunctions.ISGrabItemAction_perform = ISGrabItemAction.perform
        ISGrabItemAction.perform = ItemLogger.OnGrabItemPerform
    end
end

Events.OnGameStart.Add(ItemLogger.InitHooks)
