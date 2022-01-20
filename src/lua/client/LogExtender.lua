--
-- Copyright (c) 2022 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- LogExtender adds more logs to the Logs directory the Project Zomboid game.
--

local version = "0.6.0"

local pzversion = string.sub(getCore():getVersionNumber(), 1, 2)

local LogExtender = {
    -- Contains default config values.
    config = {
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
        },
        -- Callbacks switches.
        -- TODO: Get from server settings.
        actions = {
            player = {
                connected = true,
                levelup = true,
                tick = true,
                disconnected = false, -- TODO: How can I do this?
            },
            vehicle = {
                enter = true,
                exit = true,
                attach = true,
                detach = true,
            },
            time = true,
        },
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
    stats.Survived = player:getHoursSurvived();
    stats.Level = player:getXp():getLevel();
    if pzversion == "40" then
        stats.SkillPoints = player:getNumberOfPerksToPick();
    else
        stats.SkillPoints = 0 -- Deprecated: Removed in 41 build.
    end
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

    health.Health = bd:getOverallBodyHealth();
    health.Infected = bd:IsInfected() and "true" or "false";

    return health;
end

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
            .. '"level":' .. stats.Level .. ','
            .. '"skill_points":' .. stats.SkillPoints .. ','
            .. '"kills":' .. stats.Kills .. ','
            .. '"hours":' .. stats.Survived
            .. '}';
    else
        message = message .. " stats={}";
    end

    local health = LogExtender.getPlayerHealth(player)
    if health ~= nil then
        -- TODO: Create marshaller.
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

    writeLog(LogExtender.config.filemask.player, message);
end

LogExtender.DumpVehicle = function(player, action, vehicle, vehicle2)
    if player == nil then
        return nil;
    end

    local message = LogExtender.getLogLinePrefix(player, action);

    if vehicle then
        local info = LogExtender.getVehicleInfo(vehicle)

        message = message .. ' vehicle={'
            .. '"id":' .. info.ID .. ','
            .. '"type":' .. info.Type .. ','
            .. '"center":' .. info.Center
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
            .. '"type":' .. info.Type .. ','
            .. '"center":' .. info.Center
            .. '}';
    end

    local location = LogExtender.getLocation(player);
    message = message .. " at " .. location

    writeLog(LogExtender.config.filemask.vehicle, message);
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
                -- Fix for bug report topic
                -- https://theindiestone.com/forums/index.php?/topic/25683-nothing-will-be-written-to-the-log-if-you-take-generator-from-the-ground/
                -- Create "taken" line like another lines in *_map.txt log file.
                -- [25-08-19 16:49:39.239] 76561198204465365 "outdead" taken IsoGenerator (appliances_misc_01_0) at 10254,12759,0.
                local message = LogExtender.getLogLinePrefix(player, "taken IsoGenerator") .. " (appliances_misc_01_0) at " .. location;
                writeLog(LogExtender.config.filemask.map, message);
            elseif self.Type == "ISToggleStoveAction" then
                local message = LogExtender.getLogLinePrefix(player, "stove.toggle") .. " @ " .. location;
                writeLog(LogExtender.config.filemask.cmd, message);
            elseif self.Type == "ISPlaceCampfireAction" then
                local message = LogExtender.getLogLinePrefix(player, "added Campfire") .. " (camping_01_6) at " .. location;
                writeLog(LogExtender.config.filemask.map, message);
            elseif self.Type == "ISRemoveCampfireAction" then
                local message = LogExtender.getLogLinePrefix(player, "taken Campfire") .. " (camping_01_6) at " .. location;
                writeLog(LogExtender.config.filemask.map, message);
            elseif (self.Type == "ISLightFromKindle" or self.Type == "ISLightFromLiterature" or self.Type == "ISLightFromPetrol") then
                local message = LogExtender.getLogLinePrefix(player, "campfire.light") .. " @ " .. location;
                writeLog(LogExtender.config.filemask.cmd, message);
            elseif self.Type == "ISPutOutCampfireAction" then
                local message = LogExtender.getLogLinePrefix(player, "campfire.extinguish") .. " @ " .. location;
                writeLog(LogExtender.config.filemask.cmd, message);
            end;
        end;
    end;
end

-- OnConnected adds callback for player OnConnected event.
LogExtender.OnConnected = function()
    local player = getSpecificPlayer(0);
    if player then
        LogExtender.DumpPlayer(player, "connected");
    end
end

-- OnPerkLevel adds callback for player OnPerkLevel global event.
LogExtender.OnPerkLevel = function(player, perk, perklevel)
    if player and perk and perklevel then
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
        -- Deprecated: Old format. Will be removed on next updates.
        local location = LogExtender.getLocation(player);
        local message = LogExtender.getLogLinePrefix(player, "vehicle.enter") .. " @ " .. location;
        writeLog(LogExtender.config.filemask.cmd, message);

        -- New format.
        LogExtender.vehicle = player:getVehicle()
        LogExtender.DumpVehicle(player, "enter", LogExtender.vehicle);
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
LogExtender.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        -- Deprecated: Old format. Will be removed on next updates.
        local location = LogExtender.getLocation(player);
        local message = LogExtender.getLogLinePrefix(player, "vehicle.exit") .. " @ " .. location;
        writeLog(LogExtender.config.filemask.cmd, message);

        -- New format.
        LogExtender.DumpVehicle(player, "exit", LogExtender.vehicle);
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

    if LogExtender.config.actions.player.connected then
        LogExtender.OnConnected();
    end

    if LogExtender.config.actions.time then
        LogExtender.TimedActionPerform();
    end

    if LogExtender.config.actions.player.levelup then
        Events.LevelPerk.Add(LogExtender.OnPerkLevel);
    end

    if LogExtender.config.actions.player.tick then
        Events.EveryHours.Add(LogExtender.EveryHours);
    end

    if LogExtender.config.actions.vehicle.enter then
        Events.OnEnterVehicle.Add(LogExtender.VehicleEnter);
    end

    if LogExtender.config.actions.vehicle.exit then
        Events.OnExitVehicle.Add(LogExtender.VehicleExit);
    end

    if LogExtender.config.actions.vehicle.attach then
        LogExtender.VehicleAttach()
    end

    if LogExtender.config.actions.vehicle.detach then
        LogExtender.VehicleDetach()
    end
end

Events.OnGameStart.Add(LogExtender.OnGameStart);
