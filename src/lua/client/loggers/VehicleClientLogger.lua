--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--

local VehicleClientLogger = {
    -- Store vehicle object when user enter to it.
    vehicle = nil,
    -- Store vehicle object when user attach it.
    vehicleAttachmentA = nil,
    vehicleAttachmentB = nil,
}

-- DumpVehicle writes vehicles info to log file.
function VehicleClientLogger.DumpVehicle(player, action, vehicle, vehicle2)
    if player == nil then
        return nil;
    end

    local message = logutils.GetLogLinePrefix(player, action);

    if vehicle then
        local info = logutils.GetVehicleInfo(vehicle)

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}';
    else
        message = message .. " vehicle={}";
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
                .. '}';
    end

    local location = logutils.GetLocation(player);
    message = message .. " at " .. location

    logutils.WriteLog(logutils.filemask.vehicle, message);
end

-- VehicleEnter adds callback for OnEnterVehicle event.
VehicleClientLogger.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        VehicleClientLogger.vehicle = player:getVehicle()
        VehicleClientLogger.DumpVehicle(player, "enter", VehicleClientLogger.vehicle, nil);
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
VehicleClientLogger.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        VehicleClientLogger.DumpVehicle(player, "exit", VehicleClientLogger.vehicle, nil);
        VehicleClientLogger.vehicle = nil
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
VehicleClientLogger.VehicleAttach = function()
    local originalPerform = ISAttachTrailerToVehicle.perform;

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            VehicleClientLogger.vehicleAttachmentA = self.vehicleA
            VehicleClientLogger.vehicleAttachmentB = self.vehicleB
            VehicleClientLogger.DumpVehicle(player, "attach", self.vehicleA, self.vehicleB);
        end;
    end;
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
VehicleClientLogger.VehicleDetach = function()
    local originalPerform = ISDetachTrailerFromVehicle.perform;

    ISDetachTrailerFromVehicle.perform = function(self)
        local vehicleB = self.vehicle:getVehicleTowing()
        if vehicleB == nil then
            vehicleB = VehicleClientLogger.vehicleAttachmentB
        end

        originalPerform(self);

        local player = self.character;

        if player then
            VehicleClientLogger.DumpVehicle(player, "detach", self.vehicle, vehicleB);
            VehicleClientLogger.vehicleAttachmentA = nil;
            VehicleClientLogger.vehicleAttachmentB = nil;
        end
    end
end

--
-- Admin tools
--

-- ISSpawnVehicleUI_onClick adds logs record to admin.txt file after spawn, repair
-- vehicle and add key from vehicle in Spawn Vehicle interface.
VehicleClientLogger.ISSpawnVehicleUI_onClick = function()
    local originalOnClick = ISSpawnVehicleUI.onClick;

    ISSpawnVehicleUI.onClick = function(self, button)
        originalOnClick(self, button)

        if self.player == nil then
            return
        end

        local character = self.player

        if button.internal == "SPAWN" then
            local action = "spawned vehicle"

            local message = character:getUsername() .. " " .. action .. " " .. tostring(self:getVehicle()) .. " at " .. logutils.GetLocation(character)

            logutils.WriteLog(logutils.filemask.admin, message);
        elseif button.internal == "GETKEY" then
            if self.vehicle ~= nil then
                local action = "got vehicle key"
                local info = logutils.GetVehicleInfo(self.vehicle)

                local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

                logutils.WriteLog(logutils.filemask.admin, message);
            end
        elseif button.internal == "REPAIR" then
            if self.vehicle ~= nil then
                local action = "repaired vehicle"
                local info = logutils.GetVehicleInfo(self.vehicle)

                local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

                logutils.WriteLog(logutils.filemask.admin, message);
            end
        end
    end
end

-- OnAddVehicleCommand adds logs record to admin.txt file after spawn vehicle
-- from chat command.
VehicleClientLogger.OnAddVehicleCommand = function()
    local onCommandEnteredOriginal = ISChat.onCommandEntered;

    ISChat.onCommandEntered = function(self)
        local command = ISChat.instance.textEntry:getText():gsub("%s+", " ");
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

                                logutils.WriteLog(logutils.filemask.admin, message);
                            end

                            break;
                        end
                    end
                end
            end
        end

        onCommandEnteredOriginal(self)
    end
end

VehicleClientLogger.OnCheatRemove = function()
    local onCheatRemoveAuxOriginal = ISVehicleMechanics.onCheatRemoveAux;

    ISVehicleMechanics.onCheatRemoveAux = function(dummy, button, playerObj, vehicle)
        if button.internal ~= "NO" then
            local character = playerObj
            local action = "removed vehicle"
            local info = logutils.GetVehicleInfo(vehicle)

            local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

            logutils.WriteLog(logutils.filemask.admin, message);
        end

        onCheatRemoveAuxOriginal(dummy, button, playerObj, vehicle)
    end
end

VehicleClientLogger.OnCheatRepair = function()
    local onCheatRepairOriginal = ISVehicleMechanics.onCheatRepair;

    ISVehicleMechanics.onCheatRepair = function(playerObj, vehicle)
        local character = playerObj
        local action = "repaired vehicle"
        local info = logutils.GetVehicleInfo(vehicle)

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message);

        onCheatRepairOriginal(playerObj, vehicle)
    end
end

VehicleClientLogger.OnCheatRepairPart = function()
    local onCheatRepairPartOriginal = ISVehicleMechanics.onCheatRepairPart;

    ISVehicleMechanics.onCheatRepairPart = function(playerObj, part)
        local character = playerObj
        local action = "repaired vehicle part"
        local info = logutils.GetVehicleInfo(part:getVehicle())

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message);

        onCheatRepairPartOriginal(playerObj, part)
    end
end

VehicleClientLogger.OnCheatSetCondition = function()
    local onCheatSetConditionAuxOriginal = ISVehicleMechanics.onCheatSetConditionAux;

    ISVehicleMechanics.onCheatSetConditionAux = function(target, button, playerObj, part)
        local character = playerObj
        local action = "set vehicle part condition"
        local info = logutils.GetVehicleInfo(part:getVehicle())

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message);

        onCheatSetConditionAuxOriginal(target, button, playerObj, part)
    end
end

VehicleClientLogger.OnCheatGetKey = function()
    local onCheatGetKeyOriginal = ISVehicleMechanics.onCheatGetKey;

    ISVehicleMechanics.onCheatGetKey = function(playerObj, vehicle)
        local character = playerObj
        local action = "got vehicle key"
        local info = logutils.GetVehicleInfo(vehicle)

        local message = character:getUsername() .. " " .. action .. " " .. info.Type .. " at " .. logutils.GetLocation(character)

        logutils.WriteLog(logutils.filemask.admin, message);

        onCheatGetKeyOriginal(playerObj, vehicle)
    end
end

if SandboxVars.LogExtender.VehicleEnter then
    Events.OnEnterVehicle.Add(VehicleClientLogger.VehicleEnter)
end

if SandboxVars.LogExtender.VehicleExit then
    Events.OnExitVehicle.Add(VehicleClientLogger.VehicleExit)
end

if SandboxVars.LogExtender.VehicleAttach then
    VehicleClientLogger.VehicleAttach()
end

if SandboxVars.LogExtender.VehicleDetach then
    VehicleClientLogger.VehicleDetach()
end

if SandboxVars.LogExtender.VehicleAdminTools then
    VehicleClientLogger.ISSpawnVehicleUI_onClick()
    VehicleClientLogger.OnAddVehicleCommand()
    VehicleClientLogger.OnCheatRemove()
    VehicleClientLogger.OnCheatRepair()
    VehicleClientLogger.OnCheatRepairPart()
    VehicleClientLogger.OnCheatSetCondition()
    VehicleClientLogger.OnCheatGetKey()
end
