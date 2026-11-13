--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

local VehicleLogger = {
    vehicle = nil, -- Store vehicle object when user enter to it.
    vehicleAttachmentA = nil, -- Store vehicle object when user attach it.
    vehicleAttachmentB = nil, -- Store vehicle object when user attach it.
    initialized = false,
    recentAttacks = {},
}

function VehicleLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.VehicleLogs
end

-- DumpVehicle writes vehicles info to log file.
function VehicleLogger.DumpVehicle(character, action, vehicle, vehicle2)
    if character == nil then
        return nil
    end

    local message = ""

    if vehicle then
        message = message .. 'vehicle=' .. logutils.FormatVehicleJSON(vehicle)
    else
        message = message .. "vehicle={}"
    end

    if vehicle2 then
        message = message .. ' vehicle=' .. logutils.FormatVehicleJSON(vehicle2)
    end

    logutils.WriteLog(logutils.filemask.vehicle, action, message)
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
        local vehicle = VehicleLogger.vehicle or player:getVehicle()
        if vehicle ~= nil then
            VehicleLogger.DumpVehicle(player, "exit", vehicle, nil)
        end
        
        VehicleLogger.vehicle = nil
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
VehicleLogger.VehicleAttach = function()
    if not ISAttachTrailerToVehicle or not ISAttachTrailerToVehicle.perform then return end
    local originalPerform = ISAttachTrailerToVehicle.perform

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self)

        local player = self.character

        if player and player:isLocalPlayer() then
            VehicleLogger.vehicleAttachmentA = self.vehicleA
            VehicleLogger.vehicleAttachmentB = self.vehicleB
            VehicleLogger.DumpVehicle(player, "attach to", self.vehicleA, self.vehicleB)
        end
    end
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
VehicleLogger.VehicleDetach = function()
    if not ISDetachTrailerFromVehicle or not ISDetachTrailerFromVehicle.perform then return end
    local originalPerform = ISDetachTrailerFromVehicle.perform

    ISDetachTrailerFromVehicle.perform = function(self)
        local vehicleB = self.vehicle:getVehicleTowing()
        if vehicleB == nil then
            vehicleB = VehicleLogger.vehicleAttachmentB
        end

        originalPerform(self)

        local player = self.character

        if player and player:isLocalPlayer() then
            VehicleLogger.DumpVehicle(player, "detach from", self.vehicle, vehicleB)
            VehicleLogger.vehicleAttachmentA = nil
            VehicleLogger.vehicleAttachmentB = nil
        end
    end
end

-- VehicleSmashWindow adds logs for Smashing windows actions.
VehicleLogger.VehicleSmashWindow = function()
    if ISSmashVehicleWindow and ISSmashVehicleWindow.perform then
        local originalPerform = ISSmashVehicleWindow.perform
        
        ISSmashVehicleWindow.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle and self.part then
                local weapon = self.character:getPrimaryHandItem()
                local toolName = (weapon and instanceof(weapon, "HandWeapon")) and ('"' .. weapon:getFullType() .. '"') or '"Bare hands"'
                local pId = self.part:getId() or "Window"
                local message = 'of vehicle=' .. logutils.FormatVehicleJSON(self.vehicle) .. ' part="' .. pId .. '" using=' .. toolName
                
                logutils.WriteLog(logutils.filemask.vehicle, "smashed window", message)
            end
        end
    end

    if ISSmashWindow and ISSmashWindow.perform then
        local originalPerform = ISSmashWindow.perform
        
        ISSmashWindow.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehiclePart ~= nil then
                local veh = self.vehiclePart:getVehicle()
                local weapon = self.character:getPrimaryHandItem()
                local toolName = (weapon and instanceof(weapon, "HandWeapon")) and ('"' .. weapon:getFullType() .. '"') or '"Bare hands"'
                local pId = self.vehiclePart:getId() or "Window"
                local message = 'of vehicle=' .. logutils.FormatVehicleJSON(veh) .. ' part="' .. pId .. '" using=' .. toolName
                
                logutils.WriteLog(logutils.filemask.vehicle, "smashed window", message)
            end
        end
    end
end

-- VehicleSiphonGas adds logs for Taking gasoline from vehicle actions.
VehicleLogger.VehicleSiphonGas = function()
    if ISTakeGasolineFromVehicle and ISTakeGasolineFromVehicle.perform then
        local originalPerform = ISTakeGasolineFromVehicle.perform
        
        ISTakeGasolineFromVehicle.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle then
                local message = 'gasoline from vehicle=' .. logutils.FormatVehicleJSON(self.vehicle)
                logutils.WriteLog(logutils.filemask.vehicle, "siphoned", message)
            end
        end
    end
end

-- VehicleSiphonGas adds logs for Adding gasoline from vehicle actions.
VehicleLogger.VehicleRefuel = function()
    if ISAddGasolineToVehicle and ISAddGasolineToVehicle.perform then
        local originalPerform = ISAddGasolineToVehicle.perform
        
        ISAddGasolineToVehicle.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle then
                local itemType = (self.item and self.item.getFullType and self.item:getFullType()) or "Base.PetrolCan"
                local message = 'gasoline into vehicle=' .. logutils.FormatVehicleJSON(self.vehicle) .. ' from item="' .. itemType .. '"'
                logutils.WriteLog(logutils.filemask.vehicle, "refueled", message)
            end
        end
    end

    if ISRefuelFromGasPump and ISRefuelFromGasPump.perform then
        local originalPerform = ISRefuelFromGasPump.perform
        
        ISRefuelFromGasPump.perform = function(self)
            originalPerform(self)
            if self.character and self.character:isLocalPlayer() and self.vehicle then
                local message = 'gasoline into vehicle=' .. logutils.FormatVehicleJSON(self.vehicle) .. ' from gas pump'
                logutils.WriteLog(logutils.filemask.vehicle, "refueled", message)
            end
        end
    end
end

-- VehicleHotwire adds logs for Hotwire actions.
VehicleLogger.VehicleHotwire = function()
    if ISHotwireVehicle and ISHotwireVehicle.perform then
        local originalPerform = ISHotwireVehicle.perform
        
        ISHotwireVehicle.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() then
                local veh = self.character:getVehicle()
                if veh then
                    local message = 'vehicle=' .. logutils.FormatVehicleJSON(veh)
                    logutils.WriteLog(logutils.filemask.vehicle, "hotwired", message)
                end
            end
        end
    end
end

-- VehicleParts adds logs for vehicle parts actions.
VehicleLogger.VehicleParts = function()
    if ISUninstallVehiclePart and ISUninstallVehiclePart.perform then
        local originalPerform = ISUninstallVehiclePart.perform
        
        ISUninstallVehiclePart.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle and self.part then
                local pId = self.part:getId() or "unknown"
                local message = 'part "' .. pId .. '" from vehicle=' .. logutils.FormatVehicleJSON(self.vehicle)
                logutils.WriteLog(logutils.filemask.vehicle, "uninstalled", message)
            end
        end
    end

    if ISInstallVehiclePart and ISInstallVehiclePart.perform then
        local originalPerform = ISInstallVehiclePart.perform
        
        ISInstallVehiclePart.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle and self.part then
                local pId = self.part:getId() or "unknown"
                local message = 'part "' .. pId .. '" on vehicle=' .. logutils.FormatVehicleJSON(self.vehicle)
                logutils.WriteLog(logutils.filemask.vehicle, "installed", message)
            end
        end
    end
end

-- VehicleTirePressure adds logs for vehicle Tires actions.
VehicleLogger.VehicleTirePressure = function()
    if ISDeflateTire and ISDeflateTire.perform then
        local originalPerform = ISDeflateTire.perform
        
        ISDeflateTire.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle and self.part then
                local pId = self.part:getId() or "Tire"
                local message = 'part "' .. pId .. '" of vehicle=' .. logutils.FormatVehicleJSON(self.vehicle)
                logutils.WriteLog(logutils.filemask.vehicle, "deflated tire", message)
            end
        end
    end

    if ISInflateTire and ISInflateTire.perform then
        local originalPerform = ISInflateTire.perform
        
        ISInflateTire.perform = function(self)
            originalPerform(self)
            
            if self.character and self.character:isLocalPlayer() and self.vehicle and self.part then
                local pId = self.part:getId() or "Tire"
                local message = 'part "' .. pId .. '" of vehicle=' .. logutils.FormatVehicleJSON(self.vehicle)
                logutils.WriteLog(logutils.filemask.vehicle, "inflated tire", message)
            end
        end
    end
end

-- OnWeaponSwing adds logs for weapons actions.
VehicleLogger.OnWeaponSwing = function(character, weapon)
    if not character or not character:isLocalPlayer() then return end
    if not VehicleLogger.IsEnabledOnServer() then return end

    local cell = getCell()
    local vehicles = cell and cell:getVehicles()
    if not vehicles then return end

    local count = (vehicles.size and vehicles:size()) or (type(vehicles) == "table" and #vehicles) or 0
    if count == 0 then return end

    VehicleLogger.recentAttacks = {
        weapon = weapon,
        snapshots = {}
    }

    for i = 0, count - 1 do
        local veh = (vehicles.get and vehicles:get(i)) or vehicles[i + 1]
        if veh then
            local distSq = (character:getX() - veh:getX())^2 + (character:getY() - veh:getY())^2
            
            if distSq <= 400 then
                local vehId = veh:getId()
                local pCount = (veh.getPartCount and veh:getPartCount()) or 0
                local partConds = {}
                
                for p = 0, pCount - 1 do
                    local part = veh:getPartByIndex(p)
                    if part and part:getId() then
                        partConds[part:getId()] = part:getCondition()
                    end
                end
                
                VehicleLogger.recentAttacks.snapshots[vehId] = {
                    vehicle = veh,
                    conditions = partConds
                }
            end
        end
    end
end

VehicleLogger.OnPlayerAttackFinished = function(character)
    if not character or not character:isLocalPlayer() then return end
    if not VehicleLogger.IsEnabledOnServer() then return end
    if not VehicleLogger.recentAttacks or not VehicleLogger.recentAttacks.snapshots then return end

    local weapon = VehicleLogger.recentAttacks.weapon
    local isRanged = weapon and weapon.isRanged and weapon:isRanged()
    local action = isRanged and "attacked (ranged)" or "attacked (melee)"
    local weaponName = (weapon and weapon.getFullType) and ('"' .. weapon:getFullType() .. '"') or '"Bare hands"'

    for vehId, data in pairs(VehicleLogger.recentAttacks.snapshots) do
        local veh = data.vehicle
        if veh and veh.getPartCount then
            for p = 0, veh:getPartCount() - 1 do
                local part = veh:getPartByIndex(p)
                if part and part:getId() then
                    local pId = part:getId()
                    local preCond = data.conditions[pId]
                    local curCond = part:getCondition()
                    if preCond and curCond < preCond then
                        local dmg = preCond - curCond
                        local hpStr = "hp=" .. tostring(curCond) .. "/100"
                        if curCond <= 0 then
                            hpStr = hpStr .. " (destroyed)"
                        end
                        local message = 'vehicle=' .. logutils.FormatVehicleJSON(veh) .. ' part="' .. pId .. '" dmg=' .. tostring(dmg) .. ' ' .. hpStr .. ' using=' .. weaponName
                        logutils.WriteLog(logutils.filemask.vehicle, action, message)
                    end
                end
            end
        end
    end

    VehicleLogger.recentAttacks = {}
end

--
-- Admin tools
--

-- ISSpawnVehicleUI_onClick adds logs record to admin.txt file after spawn, repair
-- vehicle and add key from vehicle in Spawn Vehicle interface.
VehicleLogger.ISSpawnVehicleUI_onClick = function()
    if not ISSpawnVehicleUI or not ISSpawnVehicleUI.onClick then return end
    local originalOnClick = ISSpawnVehicleUI.onClick

    ISSpawnVehicleUI.onClick = function(self, button)
        originalOnClick(self, button)

        if self.player == nil then
            return
        end

        local character = self.player

        if button.internal == "SPAWN" then
            logutils.WriteLogAdmin("spawned vehicle", tostring(self:getVehicle()))
        elseif button.internal == "GETKEY" then
            if self.vehicle ~= nil then
                logutils.WriteLogAdmin("got vehicle key", logutils.GetVehicleInfo(self.vehicle).Type)
            end
        elseif button.internal == "REPAIR" then
            if self.vehicle ~= nil then
                logutils.WriteLogAdmin("repaired vehicle", logutils.GetVehicleInfo(self.vehicle).Type)
            end
        end
    end
end

VehicleLogger.DebugContextMenuCheats = function()
    if not DebugContextMenu then return end

    if DebugContextMenu.onAddVehicle then
        local originalOnAddVehicle = DebugContextMenu.onAddVehicle

        DebugContextMenu.onAddVehicle = function(character)
            logutils.WriteLogAdmin("spawned vehicle", "random")

            originalOnAddVehicle(character)
        end
    end

    if DebugContextMenu.onRemoveVehicle then
        local originalOnRemoveVehicle = DebugContextMenu.onRemoveVehicle

        DebugContextMenu.onRemoveVehicle = function(character, vehicle)
            logutils.WriteLogAdmin("removed vehicle", logutils.GetVehicleInfo(vehicle).Type)

            originalOnRemoveVehicle(character, vehicle)
        end
    end
end

-- OnAddVehicleCommand adds logs record to admin.txt file after spawn vehicle
-- from chat command.
VehicleLogger.OnAddVehicleCommand = function()
    if not ISChat or not ISChat.onCommandEntered then return end
    local onCommandEnteredOriginal = ISChat.onCommandEntered

    ISChat.onCommandEntered = function(self)
        local command = ISChat.instance.textEntry:getText():gsub("%s+", " ")
        if luautils.stringStarts(string.lower(command), "/addvehicle") then
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
                                logutils.WriteLogAdmin("spawned vehicle", code)
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
    if not ISVehicleMechanics or not ISVehicleMechanics.onCheatRemoveAux then return end
    local onCheatRemoveAuxOriginal = ISVehicleMechanics.onCheatRemoveAux

    ISVehicleMechanics.onCheatRemoveAux = function(dummy, button, character, vehicle)
        if button.internal ~= "NO" then
            logutils.WriteLogAdmin("removed vehicle", logutils.GetVehicleInfo(vehicle).Type)
        end

        onCheatRemoveAuxOriginal(dummy, button, character, vehicle)
    end
end

VehicleLogger.OnCheatRepair = function()
    if not ISVehicleMechanics or not ISVehicleMechanics.onCheatRepair then return end
    local onCheatRepairOriginal = ISVehicleMechanics.onCheatRepair

    ISVehicleMechanics.onCheatRepair = function(character, vehicle)
        logutils.WriteLogAdmin("repaired vehicle", logutils.GetVehicleInfo(vehicle).Type)

        onCheatRepairOriginal(character, vehicle)
    end
end

VehicleLogger.OnCheatRepairPart = function()
    if not ISVehicleMechanics or not ISVehicleMechanics.onCheatRepairPart then return end
    local onCheatRepairPartOriginal = ISVehicleMechanics.onCheatRepairPart

    ISVehicleMechanics.onCheatRepairPart = function(character, part)
        -- TODO: Add part to log message
        logutils.WriteLogAdmin("repaired part of vehicle", logutils.GetVehicleInfo(part:getVehicle()).Type)

        onCheatRepairPartOriginal(character, part)
    end
end

VehicleLogger.OnCheatSetCondition = function()
    if not ISVehicleMechanics or not ISVehicleMechanics.onCheatSetConditionAux then return end
    local onCheatSetConditionAuxOriginal = ISVehicleMechanics.onCheatSetConditionAux

    ISVehicleMechanics.onCheatSetConditionAux = function(target, button, character, part)
        -- TODO: Add part to log message
        logutils.WriteLogAdmin("set vehicle part condition", logutils.GetVehicleInfo(part:getVehicle()).Type)

        onCheatSetConditionAuxOriginal(target, button, character, part)
    end
end

VehicleLogger.OnCheatGetKey = function()
    if not ISVehicleMechanics or not ISVehicleMechanics.onCheatGetKey then return end
    local onCheatGetKeyOriginal = ISVehicleMechanics.onCheatGetKey

    ISVehicleMechanics.onCheatGetKey = function(character, vehicle)
        logutils.WriteLogAdmin("got vehicle key", logutils.GetVehicleInfo(vehicle).Type)

        onCheatGetKeyOriginal(character, vehicle)
    end
end

-- OnGameStart adds callback for OnGameStart global event.
VehicleLogger.OnGameStart = function()
    if VehicleLogger.initialized then return end
    VehicleLogger.initialized = true

    if VehicleLogger.IsEnabledOnServer() then
        Events.OnEnterVehicle.Add(VehicleLogger.VehicleEnter)
        Events.OnExitVehicle.Add(VehicleLogger.VehicleExit)
        VehicleLogger.VehicleAttach()
        VehicleLogger.VehicleDetach()
        VehicleLogger.VehicleSmashWindow()
        VehicleLogger.VehicleSiphonGas()
        VehicleLogger.VehicleRefuel()
        VehicleLogger.VehicleHotwire()
        VehicleLogger.VehicleParts()
        VehicleLogger.VehicleTirePressure()
        Events.OnWeaponSwing.Add(VehicleLogger.OnWeaponSwing)
        Events.OnPlayerAttackFinished.Add(VehicleLogger.OnPlayerAttackFinished)
    end

    if SandboxVars.LogExtender and SandboxVars.LogExtender.VehicleAdminTools then
        VehicleLogger.ISSpawnVehicleUI_onClick()
        VehicleLogger.DebugContextMenuCheats()
        VehicleLogger.OnAddVehicleCommand()
        VehicleLogger.OnCheatRemove()
        VehicleLogger.OnCheatRepair()
        VehicleLogger.OnCheatRepairPart()
        VehicleLogger.OnCheatSetCondition()
        VehicleLogger.OnCheatGetKey()
    end
end

Events.OnGameStart.Add(VehicleLogger.OnGameStart)
