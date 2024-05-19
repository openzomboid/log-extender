--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--

local VehiclesClientLogger = {
    Original = {
        ISSpawnVehicleUI_onClick = ISSpawnVehicleUI.onClick
    },
    -- Store vehicle object when user enter to it.
    vehicle = nil,
    -- Store vehicle object when user attach it.
    vehicleAttachmentA = nil,
    vehicleAttachmentB = nil,
}

-- DumpVehicle writes vehicles info to log file.
function VehiclesClientLogger.DumpVehicle(player, action, vehicle, vehicle2)
    if player == nil then
        return nil;
    end

    local message = LogExtenderUtils.getLogLinePrefix(player, action);

    if vehicle then
        local info = LogExtenderUtils.getVehicleInfo(vehicle)

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}';
    else
        message = message .. " vehicle={}";
    end

    if vehicle2 then
        local info = LogExtenderUtils.getVehicleInfo(vehicle2)

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

    local location = LogExtenderUtils.getLocation(player);
    message = message .. " at " .. location

    LogExtenderUtils.writeLog(LogExtenderUtils.filemask.vehicle, message);
end


-- VehicleEnter adds callback for OnEnterVehicle event.
VehiclesClientLogger.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        LogExtenderClient.vehicle = player:getVehicle()
        VehiclesClientLogger.DumpVehicle(player, "enter", LogExtenderClient.vehicle, nil);
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
VehiclesClientLogger.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        VehiclesClientLogger.DumpVehicle(player, "exit", LogExtenderClient.vehicle, nil);
        VehiclesClientLogger.vehicle = nil
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
VehiclesClientLogger.VehicleAttach = function()
    local originalPerform = ISAttachTrailerToVehicle.perform;

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            VehiclesClientLogger.vehicleAttachmentA = self.vehicleA
            VehiclesClientLogger.vehicleAttachmentB = self.vehicleB
            VehiclesClientLogger.DumpVehicle(player, "attach", self.vehicleA, self.vehicleB);
        end;
    end;
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
VehiclesClientLogger.VehicleDetach = function()
    local originalPerform = ISDetachTrailerFromVehicle.perform;

    ISDetachTrailerFromVehicle.perform = function(self)
        local vehicleB = self.vehicle:getVehicleTowing()
        if vehicleB == nil then
            vehicleB = VehiclesClientLogger.vehicleAttachmentB
        end

        originalPerform(self);

        local player = self.character;

        if player then
            VehiclesClientLogger.DumpVehicle(player, "detach", self.vehicle, vehicleB);
            VehiclesClientLogger.vehicleAttachmentA = nil;
            VehiclesClientLogger.vehicleAttachmentB = nil;
        end;
    end;
end

--
-- Admin tools
--

VehiclesClientLogger.ISSpawnVehicleUI_onClick = function(self, button)
    VehiclesClientLogger.Original.ISSpawnVehicleUI_onClick(self, button)

    if self.player == nil then
        return
    end

    local character = self.player

    if button.internal == "SPAWN" then
        character:Say(character:getUsername() .. " spawned vehicle")
    elseif button.internal == "GETKEY" then
        if self.vehicle ~= nil then
            character:Say(character:getUsername() .. " got vehicle key")
        end
    elseif button.internal == "REPAIR" then
        if self.vehicle ~= nil then
            character:Say(character:getUsername() .. " repaired vehicle")
        end
    end
end

if SandboxVars.LogExtender.VehicleEnter then
    Events.OnEnterVehicle.Add(VehiclesClientLogger.VehicleEnter)
end

if SandboxVars.LogExtender.VehicleExit then
    Events.OnExitVehicle.Add(VehiclesClientLogger.VehicleExit)
end

if SandboxVars.LogExtender.VehicleAttach then
    VehiclesClientLogger.VehicleAttach()
end

if SandboxVars.LogExtender.VehicleDetach then
    VehiclesClientLogger.VehicleDetach()
end

ISSpawnVehicleUI.onClick = VehiclesClientLogger.ISSpawnVehicleUI_onClick;
