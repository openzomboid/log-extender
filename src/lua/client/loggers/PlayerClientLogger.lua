--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- PlayerClienLogger adds players dump logs to the Logs directory the 
-- Project Zomboid game.
--

local PlayerClientLogger = {}

-- DumpPlayer writes player perks and safehouse coordinates to log file.
function PlayerClientLogger.DumpPlayer(player, action)
    if player == nil then
        return nil;
    end

    local message = logutils.GetLogLinePrefix(player, action);

    local perks = logutils.GetPlayerPerks(player);
    if perks ~= nil then
        message = message .. " perks={" .. table.concat(perks, ",") .. "}";
    else
        message = message .. " perks={}";
    end

    local traits = logutils.GetPlayerTraits(player);
    if traits ~= nil then
        message = message .. " traits=[" .. table.concat(traits, ",") .. "]";
    else
        message = message .. " traits=[]";
    end

    local stats = logutils.GetPlayerStats(player);
    if stats ~= nil then
        message = message .. ' stats={'
                .. '"profession":"' .. stats.Profession .. '",'
                .. '"kills":' .. stats.Kills .. ','
                .. '"hours":' .. stats.Survived
                .. '}';
    else
        message = message .. " stats={}";
    end

    local health = logutils.GetPlayerHealth(player)
    if health ~= nil then
        message = message .. ' health={'
                .. '"health":' .. health.Health .. ','
                .. '"infected":' .. health.Infected
                .. '}';
    else
        message = message .. " health={}";
    end

    local safehouses = logutils.GetPlayerSafehouses(player);
    if safehouses ~= nil then
        message = message .. " safehouse owner=("
        if #safehouses.Owner > 0 then
            local temp = ""

            for i = 1, #safehouses.Owner do
                local area = safehouses.Owner[i];
                temp = temp .. area.Top .. " - " .. area.Bottom;
                if i ~= #safehouses.Owner then
                    temp = temp .. ", ";
                end
            end

            message = message .. temp;
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

    local location = logutils.GetLocation(player);
    message = message .. " (" .. location .. ")"

    logutils.WriteLog(logutils.filemask.player, message);
end

-- OnCreatePlayer adds callback for player OnCreatePlayerData event.
PlayerClientLogger.OnCreatePlayer = function(id)
    Events.OnTick.Add(PlayerClientLogger.OnTick);
end

-- OnPlayerDeath adds callback for player OnPlayerDeath event.
function PlayerClientLogger.OnPlayerDeath(player)
	PlayerClientLogger.DumpPlayer(player, "death");
end

-- OnTick creates and removes ticker for emulating player connected event.
-- This is Black Magic.
PlayerClientLogger.OnTick = function()
    local player = getPlayer()
    if player then
        PlayerClientLogger.DumpPlayer(player, "connected");
        Events.OnTick.Remove(PlayerClientLogger.OnTick);
    end
end

-- OnPerkLevel adds callback for player OnPerkLevel global event.
PlayerClientLogger.OnPerkLevel = function(player, perk, level)
    if player and perk and level then
        if instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
            -- Hide events from the log when creating a character.
            if player:getHoursSurvived() <= 0 then return end

            PlayerClientLogger.DumpPlayer(player, "levelup");
        end
    end
end

-- EveryHours adds callback for EveryHours global event.
PlayerClientLogger.EveryHours = function()
    local player = getSpecificPlayer(0);
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        -- Hide events from the log when creating a character.
        if player:getHoursSurvived() <= 0 then return end

        -- Hide events from the log when character is dead.
        if player:isDead() then return end

        PlayerClientLogger.DumpPlayer(player, "tick");
    end
end

-- OnGameStart adds callback for OnGameStart global event.
PlayerClientLogger.OnGameStart = function()
    if SandboxVars.LogExtender.PlayerLevelup then
        Events.LevelPerk.Add(PlayerClientLogger.OnPerkLevel)
    end

    if SandboxVars.LogExtender.PlayerTick then
        Events.EveryHours.Add(PlayerClientLogger.EveryHours)
    end

    if SandboxVars.LogExtender.PlayerDeath then
        Events.OnPlayerDeath.Add(PlayerClientLogger.OnPlayerDeath)
    end
end

if SandboxVars.LogExtender.PlayerConnected then
    Events.OnCreatePlayer.Add(PlayerClientLogger.OnCreatePlayer);
end

Events.OnGameStart.Add(PlayerClientLogger.OnGameStart);
