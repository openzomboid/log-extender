--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

local MapLogger = {
    IsMoveablesActionAlreadyStopped = false,
    LastSwingMs = 0
}

function MapLogger.IsEnabledOnServer()
    if SandboxVars.LogExtender and SandboxVars.LogExtender.MapLogs ~= nil then
        return SandboxVars.LogExtender.MapLogs
    end

    return false
end

function MapLogger.OnGameStart()
    if not MapLogger.IsEnabledOnServer() then
        return
    end

    -- 1. Building (ISBuildAction)
    if ISBuildAction and ISBuildAction.perform then
        local origPerform = ISBuildAction.perform

        ISBuildAction.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                local bName = (self.item and self.item.name) or self.spriteName or "construction"
                logutils.WriteLog(logutils.filemask.map, "built", '"' .. bName .. '"')
            end
        end
    end

    -- 2.1 Moveables Actions (Pickup, Place)
    if ISMoveablesAction and ISMoveablesAction.perform then
        local origPerform = ISMoveablesAction.perform

        ISMoveablesAction.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() and self.mode then
                local objName = self.origSpriteName or (self.moveProps and self.moveProps.name) or (self.moveProps and self.moveProps.spriteName) or "object"
                if self.mode == "pickup" then
                    logutils.WriteLog(logutils.filemask.map, "pickedup", '"' .. objName .. '"')
                elseif self.mode == "place" then
                    logutils.WriteLog(logutils.filemask.map, "placed", '"' .. objName .. '"')
                end
            end
        end
    end

    -- 2.2 Moveables Actions (Scrap)
    if ISMoveablesAction and ISMoveablesAction.stop then
        local origStop = ISMoveablesAction.stop

        ISMoveablesAction.stop = function(self)
            origStop(self)

            if MapLogger.IsMoveablesActionAlreadyStopped then
                MapLogger.IsMoveablesActionAlreadyStopped = false
                return
            end

            local character = self.character
            if character and character:isLocalPlayer() and self.mode then
                local delta = self.getJobDelta and self:getJobDelta() or 0

                if delta >= 0.99 or (self.maxTime and self.currentTime and self.currentTime >= self.maxTime - 1) then
                    local objName = self.origSpriteName or (self.moveProps and self.moveProps.name) or (self.moveProps and self.moveProps.spriteName) or "object"
                    if self.mode == "scrap" then
                        logutils.WriteLog(logutils.filemask.map, "scrapped", '"' .. objName .. '"')
                        MapLogger.IsMoveablesActionAlreadyStopped = true
                    end
                end
            end
        end
    end

    -- 3. Unified Generator Pickup
    if ISTakeGenerator and ISTakeGenerator.perform then
        local origPerform = ISTakeGenerator.perform

        ISTakeGenerator.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                logutils.WriteLog(logutils.filemask.map, "pickedup", 'generator "Base.Generator"')
            end
        end
    end

    -- 4. Unified Trap Pickup
    if ISTakeTrap and ISTakeTrap.perform then
        local origPerform = ISTakeTrap.perform

        ISTakeTrap.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                local trapName = (self.trap and self.trap.getItem and self.trap:getItem() and self.trap:getItem():getFullType()) or "trap"
                logutils.WriteLog(logutils.filemask.map, "pickedup", 'trap "' .. trapName .. '"')
            end
        end
    end

    -- 5. Unified Campfire Pickup
    if ISRemoveCampfireAction and ISRemoveCampfireAction.perform then
        local origPerform = ISRemoveCampfireAction.perform

        ISRemoveCampfireAction.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                logutils.WriteLog(logutils.filemask.map, "pickedup", "campfire")
            end
        end
    end

    -- 6. Sledgehammer Destruction (ISDestroyStuffAction)
    if ISDestroyStuffAction and ISDestroyStuffAction.perform then
        local origPerform = ISDestroyStuffAction.perform

        ISDestroyStuffAction.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                local objName = logutils.GetThumpableName(self.item)
                local weaponName = (self.sledge and self.sledge.getFullType) and ('"' .. self.sledge:getFullType() .. '"') or '"Base.Sledgehammer"'
                logutils.WriteLog(logutils.filemask.map, "destroyed", objName .. ' with ' .. weaponName)
            end
        end
    end

    -- 7. Building Window Smashing (ISSmashWindow when vehiclePart == nil)
    if ISSmashWindow and ISSmashWindow.perform then
        local origPerform = ISSmashWindow.perform

        ISSmashWindow.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() and self.vehiclePart == nil then
                local weapon = character:getPrimaryHandItem()
                local toolName = (weapon and instanceof(weapon, "HandWeapon")) and ('"' .. weapon:getFullType() .. '"') or '"Bare hands"'
                logutils.WriteLog(logutils.filemask.map, "smashed window", 'with ' .. toolName)
            end
        end
    end

    -- 8. Barricading & Unbarricading
    if ISBarricadeAction and ISBarricadeAction.perform then
        local origPerform = ISBarricadeAction.perform

        ISBarricadeAction.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                local bType = "wooden_plank"
                if self.isMetal then bType = "metal_sheet"
                elseif self.isMetalBar then bType = "metal_bars" end
                local targetName = logutils.GetThumpableName(self.item)
                logutils.WriteLog(logutils.filemask.map, "barricaded", targetName .. ' with ' .. bType)
            end
        end
    end

    if ISUnbarricadeAction and ISUnbarricadeAction.perform then
        local origPerform = ISUnbarricadeAction.perform

        ISUnbarricadeAction.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() then
                local targetName = logutils.GetThumpableName(self.item)
                logutils.WriteLog(logutils.filemask.map, "unbarricaded", targetName)
            end
        end
    end

    -- 9. Igniting Campfire / BBQ
    local lightActions = {
        "ISLightFromLiterature", "ISLightFromPetrol", "ISLightFromKindle",
        "ISBBQLightFromLiterature", "ISBBQLightFromPetrol", "ISBBQLightFromKindle"
    }
    for _, aClass in ipairs(lightActions) do
        local cls = _G[aClass]
        if cls and cls.perform then
            local origPerform = cls.perform
            cls.perform = function(self)
                origPerform(self)
                local character = self.character
                if character and character:isLocalPlayer() then
                    logutils.WriteLog(logutils.filemask.map, "ignited", (aClass:find("BBQ") and "bbq" or "campfire"))
                end
            end
        end
    end

    -- 10. Crowbar Prying / Force Open (Build 42.22+)
    if ISForceOpen and ISForceOpen.perform then
        local origPerform = ISForceOpen.perform

        ISForceOpen.perform = function(self)
            origPerform(self)

            local character = self.character
            if character and character:isLocalPlayer() and self.object then
                local objName = logutils.GetThumpableName(self.object)
                local weapon = character:getPrimaryHandItem()
                local toolName = (weapon and weapon.getFullType) and ('"' .. weapon:getFullType() .. '"') or '"Base.Crowbar"'
                logutils.WriteLog(logutils.filemask.map, "forced open", objName .. ' with ' .. toolName)
            end
        end
    end

    -- 11. Hits on Thumpables (with actual HP) and Thumpable Destroyed (by Player or Animal)
    Events.OnWeaponSwing.Add(MapLogger.OnAnySwing)
    if Events.OnWeaponSwingHitPoint then
        Events.OnWeaponSwingHitPoint.Add(MapLogger.OnAnySwing)
    end

    -- 12. Explosions
    Events.OnThrowableExplode.Add(MapLogger.OnThrowableExplode)

    -- 13. Grid Burnt
    Events.OnGridBurnt.Add(MapLogger.OnGridBurnt)
end

function MapLogger.OnAnySwing(character, weapon)
    if not MapLogger.IsEnabledOnServer() then
        return
    end

    if not character or not instanceof(character, "IsoPlayer") or not character:isLocalPlayer() then return end

    local now = getTimestampMs and getTimestampMs() or 0
    if now > 0 and (now - MapLogger.LastSwingMs) < 150 then return end
    MapLogger.LastSwingMs = now

    local sq = character:getSquare()
    local tracked = logutils.ScanBreakablesAround(sq)

    if #tracked == 0 then return end

    local weaponName = (weapon and weapon.getFullType) and ('"' .. weapon:getFullType() .. '"') or '"Bare hands"'
    local ticks = 0

    local function checkAfter()
        ticks = ticks + 1
        if ticks < 15 then return end
        Events.OnTick.Remove(checkAfter)

        for _, item in ipairs(tracked) do
            local obj = item.obj
            local exists = obj and obj.getSquare and obj:getSquare() ~= nil
            local curHp = exists and logutils.GetThumpableHealth(obj) or 0

            if curHp and curHp < item.hp then
                local dmg = math.floor(item.hp - curHp)
                local hpStr = item.maxHp > 0
                        and string.format("hp=%d/%d", math.max(0, curHp), item.maxHp)
                        or string.format("hp=%d", math.max(0, curHp))

                local message = string.format('%s with %s damage=%d %s', item.name, weaponName, dmg, hpStr)
                logutils.WriteLog(logutils.filemask.map, "attacked", message)

                if curHp <= 0 or not exists then
                    logutils.WriteLog(logutils.filemask.map, "destroyed", item.name .. ' with ' .. weaponName)
                end
            end
        end
    end

    Events.OnTick.Add(checkAfter)
end

function MapLogger.OnThrowableExplode(trap, square)
    if not MapLogger.IsEnabledOnServer() then return end
    local character = getPlayer()
    local loc = square and logutils.GetLocation(square) or (character and logutils.GetLocation(character) or "0,0,0")
    local trapName = (trap and trap.getName and trap:getName()) or (trap and trap.getItemType and trap:getItemType()) or "explosive"

    if character then
        logutils.WriteLog(logutils.filemask.map, "exploded", 'trap "' .. trapName .. '"')
    else
        local rawLine = '0 "world" exploded trap "' .. trapName .. '" at ' .. loc
        sendClientCommand("LogExtender", "write", { mask = logutils.filemask.map, message = rawLine })
    end
end

function MapLogger.OnGridBurnt(square)
    if not MapLogger.IsEnabledOnServer() then return end
    local loc = square and logutils.GetLocation(square) or "0,0,0"
    local rawLine = '0 "world" burned square at ' .. loc
    sendClientCommand("LogExtender", "write", { mask = logutils.filemask.map, message = rawLine })
end

Events.OnGameStart.Add(MapLogger.OnGameStart)
