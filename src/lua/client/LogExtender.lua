--
-- Copyright (c) 2022 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- LogExtender adds more logs to the Logs directory the Project Zomboid game.
--

-- TODO: Create JSON marshaller.

local version = "0.7.0"

local LogExtender = {
    version = version,

    -- Placeholders for Project Zomboid log file names.
    -- Project Zomboid generates files like this 24-08-19_18-11_chat.txt
    -- at first action and use file until next server restart.
    filemask = {
        chat = "chat",
        user = "user",
        cmd = "cmd",
        vehicle = "vehicle",
        player = "player",
        item = "item",
        map = "map",
        admin = "admin",
        safehouse = "safehouse",
    },

    -- Store ingame player object when user is logged in.
    player = nil,
    -- Store vehicle object when user enter to it.
    vehicle = nil,
    -- Store vehicle object when user attach it.
    vehicleAttachment = nil,
}

-- getLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
LogExtender.getLogLinePrefix = function(player, action)
    -- TODO: Add ownerID.
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
end

-- getLocation returns players or vehicle location in "x,x,z" format.
LogExtender.getLocation = function(obj)
    return math.floor(obj:getX()) .. "," .. math.floor(obj:getY()) .. "," .. math.floor(obj:getZ());
end

-- getPlayerSafehouse iterates in server safehouse list and returns
-- area coordinates of player's houses.
LogExtender.getPlayerSafehouses = function(player)
    if player == nil then
        return nil;
    end

    local safehouses = {
        Owner = nil,
        Member = {}
    };

    local safehouseList = SafeHouse.getSafehouseList();
    for i = 0, safehouseList:size() - 1 do
        local safehouse = safehouseList:get(i);
        local owner = safehouse:getOwner();
        local members = safehouse:getPlayers();
        local area = {
            Top = safehouse:getX() .. "x" .. safehouse:getY(),
            Bottom = safehouse:getX2() .. "x" .. safehouse:getY2()
        };

        if player:getUsername() == owner then
            safehouses.Owner = area;
        elseif members:size() > 0 then
            for j = 0, members:size() - 1 do
                if members:get(j) == player:getUsername() then
                    safehouses.Member[#safehouses.Member + 1] = area;
                    break;
                end
            end
        end
    end

    return safehouses;
end

-- getPlayerPerks returns player perks table.
LogExtender.getPlayerPerks = function(player)
    if player == nil then
        return nil;
    end

    local perks = {}

    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i));

        if perk then
            local parent = perk:getParent();
            if parent ~= Perks.None then
                local perkType = tostring(perk:getType());
                local perkLevel = player:getPerkLevel(Perks.fromIndex(i));
                local key = "\"" .. perkType .. "\"";

                table.insert(perks, key .. ":" .. perkLevel);
            end
        end
    end

    table.sort(perks);

    return perks;
end

-- getPlayerTraits returns player traits table.
LogExtender.getPlayerTraits = function(player)
    if player == nil then
        return nil;
    end

    local traits = {}

    for i=0, player:getTraits():size() - 1 do
        local trait = TraitFactory.getTrait(player:getTraits():get(i));

        if trait then
            table.insert(traits, '"' .. trait:getType() .. '"');
        end
    end

    table.sort(traits);

    return traits;
end

-- getPlayerStats returns some player additional info.
LogExtender.getPlayerStats = function(player)
    if player == nil then
        return nil;
    end

    local stats = {}

    stats.Kills = player:getZombieKills();
    stats.Survived = math.floor(player:getHoursSurvived() * 100) / 100;
    stats.Profession = "";

    if player:getDescriptor() and player:getDescriptor():getProfession() then
        local prof = ProfessionFactory.getProfession(player:getDescriptor():getProfession());
        if prof then
            stats.Profession = prof:getType();
        end
    end

    return stats;
end

-- getPlayerHealth returns some player health information.
LogExtender.getPlayerHealth = function(player)
    if player == nil then
        return nil;
    end

    local bd = player:getBodyDamage()

    local health = {}

    health.Health = math.floor(bd:getOverallBodyHealth());
    health.Infected = bd:IsInfected() and "true" or "false";

    return health;
end

-- getVehicleInfo returns some vehicles information such as id, type and center
-- coordinate.
LogExtender.getVehicleInfo = function(vehicle)
    local info = {
        ID = "0",
        Type = "unknown",
        Center = "10,10,0", -- Unexisting coordinate.
    }

    if vehicle == nil then
        return info;
    end

    local id = vehicle:getID() or "0";
    local type = "unknown";

    local script = vehicle:getScript();
    if script then
        type = script:getName() or "unknown";
    end;

    info.ID = tostring(id);
    info.Type = type;
    info.Center = LogExtender.getLocation(vehicle:getCurrentSquare());

    return info;
end

-- DumpPlayer writes player perks and safehouse coordinates to log file.
LogExtender.DumpPlayer = function(player, action)
    if player == nil then
        return nil;
    end

    local message = LogExtender.getLogLinePrefix(player, action);

    local perks = LogExtender.getPlayerPerks(player);
    if perks ~= nil then
        message = message .. " perks={" .. table.concat(perks, ",") .. "}";
    else
        message = message .. " perks={}";
    end

    local traits = LogExtender.getPlayerTraits(player);
    if traits ~= nil then
        message = message .. " traits=[" .. table.concat(traits, ",") .. "]";
    else
        message = message .. " traits=[]";
    end

    local stats = LogExtender.getPlayerStats(player);
    if stats ~= nil then
        message = message .. ' stats={'
            .. '"profession":"' .. stats.Profession .. '",'
            .. '"kills":' .. stats.Kills .. ','
            .. '"hours":' .. stats.Survived
            .. '}';
    else
        message = message .. " stats={}";
    end

    local health = LogExtender.getPlayerHealth(player)
    if health ~= nil then
        message = message .. ' health={'
            .. '"health":' .. health.Health .. ','
            .. '"infected":' .. health.Infected
            .. '}';
    else
        message = message .. " health={}";
    end

    local safehouses = LogExtender.getPlayerSafehouses(player);
    if safehouses ~= nil then
        message = message .. " safehouse owner=("
        if safehouses.Owner ~= nil then
            message = message .. safehouses.Owner.Top .. " - " .. safehouses.Owner.Bottom;
        end
        message = message .. ")";

        message = message .. " safehouse member=(";
        if #safehouses.Member > 0 then
            local temp = ""

            for i = 1, #safehouses.Member do
                local area = safehouses.Member[i];
                temp = temp .. area.Top .. " - " .. area.Bottom;
                if i ~= #safehouses.Member then
                    temp = temp .. ", ";
                end
            end

            message = message .. temp;
        end
        message = message .. ")"
    else
        message = message .. " safehouse owner=() safehouse member=()"
    end

    local location = LogExtender.getLocation(player);
    message = message .. " (" .. location .. ")"

    writeLog(LogExtender.filemask.player, message);
end

-- DumpVehicle writes vehicles info to log file.
LogExtender.DumpVehicle = function(player, action, vehicle, vehicle2)
    if player == nil then
        return nil;
    end

    local message = LogExtender.getLogLinePrefix(player, action);

    if vehicle then
        local info = LogExtender.getVehicleInfo(vehicle)

        message = message .. ' vehicle={'
            .. '"id":' .. info.ID .. ','
            .. '"type":"' .. info.Type .. '",'
            .. '"center":"' .. info.Center .. '"'
            .. '}';
    else
        message = message .. " vehicle={}";
    end

    if vehicle2 then
        local info = LogExtender.getVehicleInfo(vehicle2)

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

    local location = LogExtender.getLocation(player);
    message = message .. " at " .. location

    writeLog(LogExtender.filemask.vehicle, message);
end

LogExtender.DumpSafehouse = function(player, action, safehouse, target)
    if player == nil then
        return nil;
    end

    local message = LogExtender.getLogLinePrefix(player, action);

    if safehouse then
        local area = {}
        local owner = player:getUsername()

        if instanceof(safehouse, 'SafeHouse') then
            owner = safehouse:getOwner();
            area = {
                Top = safehouse:getX() .. "x" .. safehouse:getY(),
                Bottom = safehouse:getX2() .. "x" .. safehouse:getY2(),
                zone = safehouse:getX() .. "," .. safehouse:getY() .. "," .. safehouse:getX2() - safehouse:getX() .. "," .. safehouse:getY2() - safehouse:getY()
            };
        end

        message = message .. ' ' .. area.zone
        message = message .. ' owner="' .. owner .. '"'

        if action == "release safehouse" then
            message = message .. ' members=['

            local members = safehouse:getPlayers();
            for j = 0, members:size() - 1 do
                local member = members:get(j)

                if member ~= owner then
                    message = message .. '"' .. member .. '"'
                    if j ~= members:size() - 1 then
                        message = message .. ','
                    end
                end
            end
            message = message .. ']'
        end
    else
        message = message .. ' ' .. '0,0,0,0' -- TODO: What can I do?
        message = message .. ' owner="' .. player:getUsername() .. '"'
    end

    if target ~= nil then
        message = message .. ' target="' .. target .. '"'
    end

    --local location = LogExtender.getLocation(player);
    --message = message .. " @ " .. location

    writeLog(LogExtender.filemask.safehouse, message);
end

-- TimedActionPerform overrides the original ISBaseTimedAction: perform function to gain
-- access to player events.
LogExtender.TimedActionPerform = function()
    local originalPerform = ISBaseTimedAction.perform;

    ISBaseTimedAction.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player and self.Type then
            local location = LogExtender.getLocation(player);

            if self.Type == "ISTakeGenerator" then
                local message = LogExtender.getLogLinePrefix(player, "taken IsoGenerator") .. " (appliances_misc_01_0) at " .. location;
                writeLog(LogExtender.filemask.map, message);
            elseif self.Type == "ISToggleStoveAction" then
                local message = LogExtender.getLogLinePrefix(player, "stove.toggle") .. " @ " .. location;
                writeLog(LogExtender.filemask.cmd, message);
            elseif self.Type == "ISPlaceCampfireAction" then
                local message = LogExtender.getLogLinePrefix(player, "added Campfire") .. " (camping_01_6) at " .. location;
                writeLog(LogExtender.filemask.map, message);
            elseif self.Type == "ISRemoveCampfireAction" then
                local message = LogExtender.getLogLinePrefix(player, "taken Campfire") .. " (camping_01_6) at " .. location;
                writeLog(LogExtender.filemask.map, message);
            elseif (self.Type == "ISLightFromKindle" or self.Type == "ISLightFromLiterature" or self.Type == "ISLightFromPetrol") then
                local message = LogExtender.getLogLinePrefix(player, "campfire.light") .. " @ " .. location;
                writeLog(LogExtender.filemask.cmd, message);
            elseif self.Type == "ISPutOutCampfireAction" then
                local message = LogExtender.getLogLinePrefix(player, "campfire.extinguish") .. " @ " .. location;
                writeLog(LogExtender.filemask.cmd, message);
            end;
        end;
    end;
end

LogExtender.OnTakeSafeHouse = function()
    local originalOnTakeSafeHouse = ISWorldObjectContextMenu.onTakeSafeHouse;

    ISWorldObjectContextMenu.onTakeSafeHouse = function(worldobjects, square, player)
        originalOnTakeSafeHouse(worldobjects, square, player)

        local character = getSpecificPlayer(player)
        local safehouse = nil

        local safehouseList = SafeHouse.getSafehouseList();
        -- TODO: If player owned 2 or more safehouses we can get not relevant house.
        for i = 0, safehouseList:size() - 1 do
            if safehouseList:get(i):getOwner() == character:getUsername() then
                safehouse = safehouseList:get(i);
                break;
            end
        end

        LogExtender.DumpSafehouse(character, "take safehouse", safehouse, nil)
    end
end

LogExtender.OnReleaseSafeHouse = function()
    local onClickOriginal = ISSafehouseUI.onClick;

    ISSafehouseUI.onClick = function(self, button)
        onClickOriginal(self, button)

        if button.internal == "RELEASE" then
            local character = getPlayerFromUsername(self.safehouse:getOwner())
            LogExtender.DumpSafehouse(character, "release safehouse", self.safehouse, nil)
        end
    end
end

LogExtender.OnReleaseSafeHouseCommand = function()
    local onCommandEnteredOriginal = ISChat.onCommandEntered;

    ISChat.onCommandEntered = function(self)
        local command = ISChat.instance.textEntry:getText();
        if command == "/releasesafehouse" then
            local character = getSpecificPlayer(0)
            local safehouse = nil

            local safehouseList = SafeHouse.getSafehouseList();
            -- TODO: If player owned 2 or more safehouses we can get not relevant house.
            for i = 0, safehouseList:size() - 1 do
                if safehouseList:get(i):getOwner() == character:getUsername() then
                    safehouse = safehouseList:get(i);
                    break;
                end
            end

            LogExtender.DumpSafehouse(character, "release safehouse", safehouse, nil)
        end

        onCommandEnteredOriginal(self)
    end
end

LogExtender.OnRemovePlayerFromSafehouse = function()
    local onRemovePlayerFromSafehouseOriginal = ISSafehouseUI.onRemovePlayerFromSafehouse;

    ISSafehouseUI.onRemovePlayerFromSafehouse = function(self, button, player)
        if button.internal == "YES" then
            local character = getPlayer()
            LogExtender.DumpSafehouse(character, "remove player from safehouse", button.parent.ui.safehouse, button.parent.ui.selectedPlayer)
        end

        onRemovePlayerFromSafehouseOriginal(self, button, player)
    end
end

LogExtender.OnJoinToSafehouse = function()
    local onAnswerSafehouseInviteOriginal = ISSafehouseUI.onAnswerSafehouseInvite;

    ISSafehouseUI.onAnswerSafehouseInvite = function(self, button)
        if button.internal == "YES" then
            local character = getPlayer()
            LogExtender.DumpSafehouse(character, "join to safehouse", button.parent.safehouse, nil)
        end

        onAnswerSafehouseInviteOriginal(self, button)
    end
end

-- OnConnected adds callback for player OnConnected event.
LogExtender.OnConnected = function()
    local player = getSpecificPlayer(0);
    if player then
        LogExtender.DumpPlayer(player, "connected");
    end
end

-- OnPerkLevel adds callback for player OnPerkLevel global event.
LogExtender.OnPerkLevel = function(player, perk, level)
    if player and perk and level then
        if instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
            -- Hide events from the log when creating a character.
            if player:getHoursSurvived() <= 0 then return end

            LogExtender.DumpPlayer(player, "levelup");
        end
    end
end

-- EveryHours adds callback for EveryHours global event.
LogExtender.EveryHours = function()
    local player = getSpecificPlayer(0);
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        -- Hide events from the log when creating a character.
        if player:getHoursSurvived() <= 0 then return end

        LogExtender.DumpPlayer(player, "tick");
    end
end

-- VehicleEnter adds callback for OnEnterVehicle event.
LogExtender.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        LogExtender.vehicle = player:getVehicle()
        LogExtender.DumpVehicle(player, "enter", LogExtender.vehicle, nil);
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
LogExtender.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        LogExtender.DumpVehicle(player, "exit", LogExtender.vehicle, nil);
        LogExtender.vehicle = nil
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
LogExtender.VehicleAttach = function()
    local originalPerform = ISAttachTrailerToVehicle.perform;

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            LogExtender.vehicleAttachment = self.vehicleB
            LogExtender.DumpVehicle(player, "attach", self.vehicleA, self.vehicleB);
        end;
    end;
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
LogExtender.VehicleDetach = function()
    local originalPerform = ISDetachTrailerFromVehicle.perform;

    ISDetachTrailerFromVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            LogExtender.DumpVehicle(player, "detach", self.vehicle, LogExtender.vehicleAttachment);
            LogExtender.vehicleAttachment = nil;
        end;
    end;
end

-- OnGameStart adds callback for OnGameStart global event.
LogExtender.OnGameStart = function()
    LogExtender.player = getSpecificPlayer(0);

    if SandboxVars.LogExtender.PlayerConnected then
        LogExtender.OnConnected();
    end

    if SandboxVars.LogExtender.PlayerLevelup then
        Events.LevelPerk.Add(LogExtender.OnPerkLevel);
    end

    if SandboxVars.LogExtender.PlayerTick then
        Events.EveryHours.Add(LogExtender.EveryHours);
    end

    if SandboxVars.LogExtender.VehicleEnter then
        Events.OnEnterVehicle.Add(LogExtender.VehicleEnter);
    end

    if SandboxVars.LogExtender.VehicleExit then
        Events.OnExitVehicle.Add(LogExtender.VehicleExit);
    end

    if SandboxVars.LogExtender.VehicleAttach then
        LogExtender.VehicleAttach()
    end

    if SandboxVars.LogExtender.VehicleDetach then
        LogExtender.VehicleDetach()
    end

    if SandboxVars.LogExtender.TimedActions then
        LogExtender.TimedActionPerform();
    end

    if SandboxVars.LogExtender.TakeSafeHouse then
        LogExtender.OnTakeSafeHouse()
    end

    if SandboxVars.LogExtender.ReleaseSafeHouse then
        LogExtender.OnReleaseSafeHouse()
    end

    if SandboxVars.LogExtender.RemovePlayerFromSafehouse then
        LogExtender.OnRemovePlayerFromSafehouse()
    end

    if SandboxVars.LogExtender.JoinToSafehouse then
        LogExtender.OnJoinToSafehouse()
    end
end

if SandboxVars.LogExtender.ReleaseSafeHouse then
    LogExtender.OnReleaseSafeHouseCommand()
end

Events.OnGameStart.Add(LogExtender.OnGameStart);
