--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

local VehicleLogger = {
    -- Store vehicle object when user enter to it.
    vehicle = nil,
    -- Store vehicle object when user attach it.
    vehicleAttachmentA = nil,
    vehicleAttachmentB = nil,
}

function VehicleLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.VehicleLogs
end

-- DumpVehicle writes vehicles info to log file.
function VehicleLogger.DumpVehicle(player, action, vehicle, vehicle2)
    if player == nil then
        return nil
    end

    local message = logutils.GetLogLinePrefix(player, action)

    if vehicle then
        local info = logutils.GetVehicleInfo(vehicle)

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}'
    else
        message = message .. " vehicle={}"
    end

    if vehicle2 then
        local info = logutils.GetVehicleInfo(vehicle2)

        if action == 'attach' then
            message = message .. ' to'
        elseif action == 'detach' then
            message = message .. ' from'
        end

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}'
    end

    local location = logutils.GetLocation(player)
    message = message .. " at " .. location

    logutils.WriteLog(logutils.filemask.vehicle, message)
end

-- VehicleEnter adds callback for OnEnterVehicle event.
VehicleLogger.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        if VehicleLogger.vehicle == nil then
            VehicleLogger.vehicle = player:getVehicle()
            VehicleLogger.DumpVehicle(player, "enter", VehicleLogger.vehicle, nil)
        end
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
VehicleLogger.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        if VehicleLogger.vehicle ~= nil then
            VehicleLogger.DumpVehicle(player, "exit", VehicleLogger.vehicle, nil)
            VehicleLogger.vehicle = nil
        end
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
VehicleLogger.VehicleAttach = function()
    local originalPerform = ISAttachTrailerToVehicle.perform

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self)

        local player = self.character

        if player then
            VehicleLogger.vehicleAttachmentA = self.vehicleA
            VehicleLogger.vehicleAttachmentB = self.vehicleB
            VehicleLogger.DumpVehicle(player, "attach", self.vehicleA, self.vehicleB)
        end
    end
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
VehicleLogger.VehicleDetach = function()
    local originalPerform = ISDetachTrailerFromVehicle.perform

    ISDetachTrailerFromVehicle.perform = function(self)
        local vehicleB = self.vehicle:getVehicleTowing()
        if vehicleB == nil then
            vehicleB = VehicleLogger.vehicleAttachmentB
        end

        originalPerform(self)

        local player = self.character

        if player then
            VehicleLogger.DumpVehicle(player, "detach", self.vehicle, vehicleB)
            VehicleLogger.vehicleAttachmentA = nil
            VehicleLogger.vehicleAttachmentB = nil
        end
    end
end

if VehicleLogger.IsEnabledOnServer() then
    Events.OnEnterVehicle.Add(VehicleLogger.VehicleEnter)
    Events.OnExitVehicle.Add(VehicleLogger.VehicleExit)
    VehicleLogger.VehicleAttach()
    VehicleLogger.VehicleDetach()
end

--
-- Admin tools
--

-- ISSpawnVehicleUI_onClick adds logs record to admin.txt file after spawn, repair
-- vehicle and add key from vehicle in Spawn Vehicle interface.
VehicleLogger.ISSpawnVehicleUI_onClick = function()
    local originalOnClick = ISSpawnVehicleUI.onClick

    ISSpawnVehicleUI.onClick = function(self, button)
        originalOnClick(self, button)

        if self.player == nil then
            return
        end

        local character = self.player

        if button.internal == "SPAWN" then
            local action = "spawned vehicle"

            local message = character:getUsername() .. " " .. action .. " " .. tostring(self:getVehicle()) .. " at " .. logutils.GetLocation(character)

            logutils.WriteLog(logutils.filemask.admin, message)
        elseif button.internal == "GETKEY" then
            if self.vehicle ~= nil then
                local action = "got vehicle key"
                local info = logutils.GetVehicleInfo(self.vehicle)

                local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

                logutils.WriteLog(logutils.filemask.admin, message)
            end
        elseif button.internal == "REPAIR" then
            if self.vehicle ~= nil then
                local action = "repaired vehicle"
                local info = logutils.GetVehicleInfo(self.vehicle)

                local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

                logutils.WriteLog(logutils.filemask.admin, message)
            end
        end
    end
end

VehicleLogger.DebugContextMenuCheats = function()
    local originalOnAddVehicle = DebugContextMenu.onAddVehicle

    DebugContextMenu.onAddVehicle = function(character)
        local action = "spawned vehicle"

        local message = character:getUsername() .. " " .. action .. " " .. "random" .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message)

        originalOnAddVehicle(character)
    end

    local originalOnRemoveVehicle = DebugContextMenu.onRemoveVehicle

    DebugContextMenu.onRemoveVehicle = function(character, vehicle)
        local action = "removed vehicle"
        local info = logutils.GetVehicleInfo(vehicle)

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message)

        originalOnRemoveVehicle(character, vehicle)
    end
end

-- OnAddVehicleCommand adds logs record to admin.txt file after spawn vehicle
-- from chat command.
VehicleLogger.OnAddVehicleCommand = function()
    local onCommandEnteredOriginal = ISChat.onCommandEntered

    ISChat.onCommandEntered = function(self)
        local command = ISChat.instance.textEntry:getText():gsub("%s+", " ")
        if luautils.stringStarts(string.lower(command), "/addvehicle") then
            local action = "spawned vehicle"
            local character = getSpecificPlayer(0)
            local splitCommand = luautils.split(command, " ")

            if #splitCommand == 2 or #splitCommand == 3 then
                local code = splitCommand[2]
                if code ~= "" then
                    local scripts = getScriptManager():getAllVehicleScripts()
                    for i=1, scripts:size() do
                        local script = scripts:get(i-1)
                        if code == script:getFullName() or code == script:getName() then
                            local doLogMessage = true

                            if #splitCommand == 3 then
                                doLogMessage = false

                                local onlineUsers = getOnlinePlayers()

                                for j=0, onlineUsers:size()-1 do
                                    local username = onlineUsers:get(j):getUsername()
                                    if username == splitCommand[3] then
                                        doLogMessage = true
                                    end
                                end
                            end

                            if doLogMessage then
                                local message = character:getUsername() .. " " .. action .. " " .. code .. " at " .. logutils.GetLocation(character)

                                logutils.WriteLog(logutils.filemask.admin, message)
                            end

                            break
                        end
                    end
                end
            end
        end

        onCommandEnteredOriginal(self)
    end
end

VehicleLogger.OnCheatRemove = function()
    local onCheatRemoveAuxOriginal = ISVehicleMechanics.onCheatRemoveAux

    ISVehicleMechanics.onCheatRemoveAux = function(dummy, button, character, vehicle)
        if button.internal ~= "NO" then
            local action = "removed vehicle"
            local info = logutils.GetVehicleInfo(vehicle)

            local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

            logutils.WriteLog(logutils.filemask.admin, message)
        end

        onCheatRemoveAuxOriginal(dummy, button, character, vehicle)
    end
end

VehicleLogger.OnCheatRepair = function()
    local onCheatRepairOriginal = ISVehicleMechanics.onCheatRepair

    ISVehicleMechanics.onCheatRepair = function(character, vehicle)
        local action = "repaired vehicle"
        local info = logutils.GetVehicleInfo(vehicle)

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message)

        onCheatRepairOriginal(character, vehicle)
    end
end

VehicleLogger.OnCheatRepairPart = function()
    local onCheatRepairPartOriginal = ISVehicleMechanics.onCheatRepairPart

    ISVehicleMechanics.onCheatRepairPart = function(character, part)
        local action = "repaired vehicle part"
        local info = logutils.GetVehicleInfo(part:getVehicle())

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message)

        onCheatRepairPartOriginal(character, part)
    end
end

VehicleLogger.OnCheatSetCondition = function()
    local onCheatSetConditionAuxOriginal = ISVehicleMechanics.onCheatSetConditionAux

    ISVehicleMechanics.onCheatSetConditionAux = function(target, button, character, part)
        local action = "set vehicle part condition"
        local info = logutils.GetVehicleInfo(part:getVehicle())

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message)

        onCheatSetConditionAuxOriginal(target, button, character, part)
    end
end

VehicleLogger.OnCheatGetKey = function()
    local onCheatGetKeyOriginal = ISVehicleMechanics.onCheatGetKey

    ISVehicleMechanics.onCheatGetKey = function(character, vehicle)
        local action = "got vehicle key"
        local info = logutils.GetVehicleInfo(vehicle)

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message)

        onCheatGetKeyOriginal(character, vehicle)
    end
end

if SandboxVars.LogExtender.VehicleAdminTools then
    VehicleLogger.ISSpawnVehicleUI_onClick()
    VehicleLogger.DebugContextMenuCheats()
    VehicleLogger.OnAddVehicleCommand()
    VehicleLogger.OnCheatRemove()
    VehicleLogger.OnCheatRepair()
    VehicleLogger.OnCheatRepairPart()
    VehicleLogger.OnCheatSetCondition()
    VehicleLogger.OnCheatGetKey()
end
