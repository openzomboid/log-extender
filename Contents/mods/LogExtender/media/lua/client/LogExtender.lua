--
-- LogExtender adds more logs for Project Zomboid Logs directory.
-- Copyright (c) 2019 outdead.
--
-- This is a test version for server Last Day (last-day.wargm.ru)
-- It is not recommended to be used on your own server while this line exists.
--

-- playerLogFilemask is a placeholder for log file. Project Zomboid generates file
-- like this 24-08-19_18-11_player.txt.
local playerLogFilemask = "player"

-- getLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
local function getLogLinePrefix(player, action)
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
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

-- OnConnectedCallback adds callback for player OnPerkLevel event.
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
