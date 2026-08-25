--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

-- PlayerLogger adds players logs to the Zomboid/Logs directory.
local PlayerLogger = {}

function PlayerLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.PlayerLogs
end

-- DumpPlayer writes player perks and safehouse coordinates to log file.
function PlayerLogger.DumpPlayer(character, action)
    if character == nil then return nil end

    local message = logutils.GetLogLinePrefix(character, action)

    local perks = logutils.GetPlayerPerks(character)
    if perks ~= nil then
        message = message .. " perks={" .. table.concat(perks, ",") .. "}"
    else
        message = message .. " perks={}"
    end

    local traits = logutils.GetPlayerTraits(character)
    if traits ~= nil then
        message = message .. " traits=[" .. table.concat(traits, ",") .. "]"
    else
        message = message .. " traits=[]"
    end

    local stats = logutils.GetPlayerStats(character)
    if stats ~= nil then
        message = message .. ' stats={'
                .. '"profession":"' .. stats.Profession .. '",'
                .. '"kills":' .. stats.Kills .. ','
                .. '"hours":' .. stats.Survived
                .. '}'
    else
        message = message .. " stats={}"
    end

    local health = logutils.GetPlayerHealth(character)
    if health ~= nil then
        message = message .. ' health={'
                .. '"health":' .. health.Health .. ','
                .. '"infected":' .. health.Infected
                .. '}'
    else
        message = message .. " health={}"
    end

    local safehouses = logutils.GetPlayerSafehouses(character)
    if safehouses ~= nil then
        message = message .. " safehouse owner=("
        if #safehouses.Owner > 0 then
            local temp = ""

            for i = 1, #safehouses.Owner do
                local area = safehouses.Owner[i]
                temp = temp .. area.Top .. " - " .. area.Bottom
                if i ~= #safehouses.Owner then
                    temp = temp .. ", "
                end
            end

            message = message .. temp
        end
        message = message .. ")"

        message = message .. " safehouse member=("
        if #safehouses.Member > 0 then
            local temp = ""

            for i = 1, #safehouses.Member do
                local area = safehouses.Member[i]
                temp = temp .. area.Top .. " - " .. area.Bottom
                if i ~= #safehouses.Member then
                    temp = temp .. ", "
                end
            end

            message = message .. temp
        end
        message = message .. ")"
    else
        message = message .. " safehouse owner=() safehouse member=()"
    end

    local location = logutils.GetLocation(character)
    message = message .. " (" .. location .. ")"

    logutils.WriteLog(logutils.filemask.player, message)
end

-- OnCreatePlayer adds callback for player OnCreatePlayerData event.
PlayerLogger.OnCreatePlayer = function(id)
    Events.OnTick.Add(PlayerLogger.OnTick)
end

-- OnPlayerDeath adds callback for player OnPlayerDeath event.
function PlayerLogger.OnPlayerDeath(player)
	PlayerLogger.DumpPlayer(player, "death")
end

-- OnTick creates and removes ticker for emulating player connected event.
-- This is Black Magic.
PlayerLogger.OnTick = function()
    local player = getPlayer()
    if player then
        Events.OnTick.Remove(PlayerLogger.OnTick)
        PlayerLogger.DumpPlayer(player, "connected")
    end
end

-- OnPerkLevel adds callback for player OnPerkLevel global event.
PlayerLogger.OnPerkLevel = function(player, perk, level)
    if player and perk and level then
        if instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
            -- Hide events from the log when creating a character.
            if player:getHoursSurvived() <= 0 then return end

            PlayerLogger.DumpPlayer(player, "levelup")
        end
    end
end

-- EveryHours adds callback for EveryHours global event.
PlayerLogger.EveryHours = function()
    local player = getSpecificPlayer(0)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        -- Hide events from the log when creating a character.
        if player:getHoursSurvived() <= 0 then return end

        -- Hide events from the log when character is dead.
        if player:isDead() then return end

        PlayerLogger.DumpPlayer(player, "tick")
    end
end

-- OnGameStart adds callback for OnGameStart global event.
PlayerLogger.OnGameStart = function()
    if PlayerLogger.IsEnabledOnServer() then
        Events.LevelPerk.Add(PlayerLogger.OnPerkLevel)
    end

    if PlayerLogger.IsEnabledOnServer() and SandboxVars.LogExtender.PlayerTickLogs then
        Events.EveryHours.Add(PlayerLogger.EveryHours)
    end

    if PlayerLogger.IsEnabledOnServer() then
        Events.OnPlayerDeath.Add(PlayerLogger.OnPlayerDeath)
    end
end

if PlayerLogger.IsEnabledOnServer() then
    Events.OnCreatePlayer.Add(PlayerLogger.OnCreatePlayer)
end

Events.OnGameStart.Add(PlayerLogger.OnGameStart)
