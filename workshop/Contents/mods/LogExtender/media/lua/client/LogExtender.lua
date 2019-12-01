--
-- Copyright (c) 2019 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- LogExtender adds more logs to the Logs directory the Project Zomboid game.
--

local version = "0.3.0"

local LogExtender = {
    -- Contains default config values.
    config = {
        -- Placeholders for Project Zomboid log file names.
        -- Project Zomboid generates files like this 24-08-19_18-11_chat.txt
        -- at firts action and use file until next server restart.
        filemask = {
            chat = "chat",
            user = "user",
            cmd = "cmd",
            player = "player",
            item = "item",
            map = "map",
            admin = "admin",
        },
        -- Callbacks switches.
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
            },
            time = true,
        },
    },
    -- Store ingame player object when user is logged in.
    player = nil,
}

-- getLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
LogExtender.getLogLinePrefix = function(player, action)
    -- TODO: Add ownerID.
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
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

-- getPlayerStats returns some player additional info.
LogExtender.getPlayerStats = function(player)
    if player == nil then
        return nil;
    end

    local stats = {}

    stats.Kills = player:getZombieKills();
    stats.Survived = player:getHoursSurvived();
    stats.Level = player:getXp():getLevel();

    return stats;
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
        --TODO: print an error if perks is nil?
        message = message .. " perks={}";
    end

    local stats = LogExtender.getPlayerStats(player);
    if stats ~= nil then
        message = message .. " stats={\"level\":" .. stats.Level .. ",\"kills\":" .. stats.Kills .. ",\"hours\":" .. stats.Survived .. "}";
    else
        message = message .. " stats={}";
    end

    local safehouses = LogExtender.getPlayerSafehouses(player);
    if safehouses ~= nil then
        message = message .. " safehouse owner=("
        if safehouses.Owner ~= nil then
            message = message .. safehouses.Owner.Top .. " - " .. safehouses.Owner.Bottom;
        end
        message = message .. ")";

        message = message .. " safehouse member=(";
        if #safehouses.Member > 1 then
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

    writeLog(LogExtender.config.filemask.player, message);
end

-- TimedActionPerform overrides the original ISBaseTimedAction: perform function to gain
-- access to player events.
LogExtender.TimedActionPerform = function()
    local originalPerform = ISBaseTimedAction.perform;

    ISBaseTimedAction.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player and self.Type then
            -- Fix for bug report topic
            -- https://theindiestone.com/forums/index.php?/topic/25683-nothing-will-be-written-to-the-log-if-you-take-generator-from-the-ground/
            -- Create "taken" line like another lines in *_map.txt log file.
            -- [25-08-19 16:49:39.239] 76561198204465365 "outdead" taken IsoGenerator (appliances_misc_01_0) at 10254,12759,0.
            if self.Type == "ISTakeGenerator" then
                local location = math.floor(player:getX()) .. "," .. math.floor(player:getY()) .. "," .. math.floor(player:getZ());
                local message = LogExtender.getLogLinePrefix(player, "taken IsoGenerator") .. " (appliances_misc_01_0) at " .. location;
                writeLog(LogExtender.config.filemask.map, message);
            end;
        end;
    end;
end

-- OnConnected adds callback for player OnConnected event.
LogExtender.OnConnected = function()
    local player = getSpecificPlayer(0);
    if player then
        --LogExtender.player = player;
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

-- VehicleEnter adds collback for OnEnterVehicle event.
LogExtender.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        local location = math.floor(player:getX()) .. "," .. math.floor(player:getY()) .. "," .. math.floor(player:getZ());
        local message = LogExtender.getLogLinePrefix(player, "vehicle.enter") .. " @ " .. location;
        writeLog(LogExtender.config.filemask.cmd, message);
    end
end

-- VehicleExit adds collback for OnExitVehicle event.
LogExtender.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        local location = math.floor(player:getX()) .. "," .. math.floor(player:getY()) .. "," .. math.floor(player:getZ());
        local message = LogExtender.getLogLinePrefix(player, "vehicle.exit") .. " @ " .. location;
        writeLog(LogExtender.config.filemask.cmd, message);
    end
end

-- OnGameStart adds callback for OnGameStart global event.
LogExtender.OnGameStart = function()
    if LogExtender.config.actions.player.connected then
        LogExtender.OnConnected();
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
end

Events.OnGameStart.Add(LogExtender.OnGameStart);
