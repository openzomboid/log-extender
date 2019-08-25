--
-- Copyright (c) 2019 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- LogExtender adds more logs to the Logs directory the Project Zomboid game.
--

-- playerLogFilemask is a placeholder for custom player log file. Project Zomboid generates file
-- like this 24-08-19_18-11_player.txt at firts action and use file until next server restart.
local playerLogFilemask = "player"

-- mapLogFilemask is a placeholder for ingame user log file. Project Zomboid generates file
-- like this 24-08-19_18-11_map.txt at firts action and use file until next server restart.
local mapLogFilemask = "map"

-- getLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
local function getLogLinePrefix(player, action)
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
end

-- TimedActionPerform overrides the original ISBaseTimedAction: perform function to gain
-- access to player events.
local function TimedActionPerform()
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
                local message = getLogLinePrefix(player, "taken IsoGenerator") .. " (appliances_misc_01_0) at " .. location;
                writeLog(mapLogFilemask, message);
            end;
        end;
    end;
end

-- getPlayerSafehouse iterates in server safehouse list and returns
-- area coordinates of player's houses.
local function getPlayerSafehouses(player)
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
local function getPlayerPerks(player)
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
local function getPlayerStats(player)
    if player == nil then
        return nil;
    end

    local stats = {}

    stats.Kills = player:getZombieKills();
    stats.Survived = player:getHoursSurvived();

    return stats;
end

-- DumpPlayer writes player perks and safehouse coordinates to log file.
local function DumpPlayer(player, action)
    if player == nil then
        return nil;
    end

    local message = getLogLinePrefix(player, action);

    local perks = getPlayerPerks(player);
    --TODO: print an error if perks is nil?
    if perks ~= nil then
        message = message .. " perks={" .. table.concat(perks, ",") .. "}";
    end

    local stats = getPlayerStats(player);
    if stats ~= nil then
        message = message .. " stats={\"kills\":" .. stats.Kills .. ",\"hours\":" .. stats.Survived .. "}";
    end

    local safehouses = getPlayerSafehouses(player);
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
    end

    writeLog(playerLogFilemask, message);
end

-- OnConnectedCallback adds callback for player OnConnected event.
local function OnConnectedCallback()
    local player = getSpecificPlayer(0);
    if player then
        DumpPlayer(player, "connected");
    end
end

-- OnPerkLevelCallback adds callback for player OnPerkLevel event.
local function OnPerkLevelCallback(player, perk, perklevel)
    if player and perk and perklevel then
        --player:Say("I Think I'm Paranoid");
        DumpPlayer(player, "levelup");
    end
end

-- OnGameStartCallback adds callback for OnGameStart event.
local function OnGameStartCallback()
    OnConnectedCallback();

    Events.LevelPerk.Add(OnPerkLevelCallback);
end

Events.OnGameStart.Add(OnGameStartCallback);
Events.OnGameStart.Add(TimedActionPerform);
