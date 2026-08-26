--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

logutils = {
    version = "0.14.0", -- in semantic versioning (http://semver.org/)
    pzversion = getCore():getVersionNumber(),

    -- Placeholders for Project Zomboid log file names.
    -- Project Zomboid generates files like this 2006-01-02_15-04_chat.txt
    -- at first action and use file until next server restart.
    filemask = {
        player = "player",
        vehicle = "vehicle",
        brushtool = "brushtool",
        safehouse = "safehouse",
        craft = "craft",

        admin = "admin",
        user = "user",
        cmd = "cmd",
        item = "item",
        map = "map",
        pvp = "pvp",
        chat = "chat",

        map_alternative = "map_alternative",
    },
}

-- WriteLog sends command to server for writting log line to file.
function logutils.WriteLog(filemask, message)
    sendClientCommand("LogExtender", "write", { mask = filemask, message = message })
end

-- GetLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
function logutils.GetLogLinePrefix(player, action)
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
end

-- GetLocation returns players or vehicle location in "x,x,z" format.
function logutils.GetLocation(obj)
    return math.floor(obj:getX()) .. "," .. math.floor(obj:getY()) .. "," .. math.floor(obj:getZ())
end

-- GetPlayerSafehouses iterates in server safehouse list and returns
-- area coordinates of player's houses.
function logutils.GetPlayerSafehouses(player)
    if player == nil then
        return nil
    end

    local safehouses = {
        Owner = {},
        Member = {}
    }

    local safehouseList = SafeHouse.getSafehouseList()
    for i = 0, safehouseList:size() - 1 do
        local safehouse = safehouseList:get(i)
        local owner = safehouse:getOwner()
        local members = safehouse:getPlayers()
        local area = {
            Top = safehouse:getX() .. "x" .. safehouse:getY(),
            Bottom = safehouse:getX2() .. "x" .. safehouse:getY2()
        }

        if player:getUsername() == owner then
            safehouses.Owner[#safehouses.Owner + 1] = area
        elseif members:size() > 0 then
            for j = 0, members:size() - 1 do
                if members:get(j) == player:getUsername() then
                    safehouses.Member[#safehouses.Member + 1] = area
                    break
                end
            end
        end
    end

    return safehouses
end

-- GetPlayerPerks returns player perks table.
function logutils.GetPlayerPerks(character)
    if character == nil then
        return nil
    end

    local perks = {}

    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i))

        if perk then
            local parent = perk:getParent()
            if parent ~= Perks.None then
                local perkType = tostring(perk:getType())
                local perkLevel = character:getPerkLevel(Perks.fromIndex(i))
                local key = "\"" .. perkType .. "\""

                table.insert(perks, key .. ":" .. perkLevel)
            end
        end
    end

    table.sort(perks)

    return perks
end

-- GetPlayerTraits returns player traits table.
function logutils.GetPlayerTraits(character)
    if character == nil then return nil end

    local traits = {}

    for i=0, character:getCharacterTraits():getKnownTraits():size() - 1 do
        local trait = CharacterTraitDefinition.getCharacterTraitDefinition(character:getCharacterTraits():getKnownTraits():get(i))
        if trait and trait:getTexture() then
            table.insert(traits, '"' .. trait:getType():getName() .. '"')
        end
    end

    table.sort(traits)

    return traits
end

-- GetPlayerStats returns some player additional info.
function logutils.GetPlayerStats(character)
    if character == nil then
        return nil
    end

    local stats = {}

    stats.Kills = character:getZombieKills()
    stats.Survived = math.floor(character:getHoursSurvived() * 100) / 100
    stats.Profession = ""

    if character:getDescriptor() and character:getDescriptor():getCharacterProfession() then
        local prof = CharacterProfessionDefinition.getCharacterProfessionDefinition(character:getDescriptor():getCharacterProfession())
        if prof then
            stats.Profession = prof:getType():getName()
        end
    end

    return stats
end

-- GetPlayerHealth returns some player health information.
function logutils.GetPlayerHealth(character)
    if character == nil then
        return nil
    end

    local bd = character:getBodyDamage()

    local health = {}

    health.Health = math.floor(bd:getOverallBodyHealth())
    health.Infected = bd:IsInfected() and "true" or "false"

    return health
end

-- GetVehicleInfo returns some vehicles information such as id, type and center
-- coordinate.
function logutils.GetVehicleInfo(vehicle)
    local info = {
        ID = "0",
        Type = "unknown",
        Center = "10,10,0", -- Unexisting coordinate.
    }

    if vehicle == nil then
        return info
    end

    local id = vehicle:getID() or "0"
    local type = "unknown"

    local script = vehicle:getScript()
    if script then
        type = script:getName() or "unknown"
    end

    info.ID = tostring(id)
    info.Type = type
    info.Center = logutils.GetLocation(vehicle:getCurrentSquare())

    return info
end

-- GetSafehouseShortNotation returns Safehouse area in "x,y,w,h" format.
function logutils.GetSafehouseShortNotation(safehouse)
    if not safehouse then
        return "0,0,0,0"
    end

    local x = math.floor(math.min(safehouse:getX(), safehouse:getX2()))
    local y = math.floor(math.min(safehouse:getY(), safehouse:getY2()))
    local w = math.floor(math.abs(safehouse:getX() - safehouse:getX2()))
    local h = math.floor(math.abs(safehouse:getY() - safehouse:getY2()))

    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(w) .. "," .. tostring(h)
end

function logutils.GetOptionFromName(currentContext, name)
    if not currentContext or not currentContext.options then return end

    for _, option in ipairs(currentContext.options) do
        if option.name == name then
            return option
        end

        if option.subOption then
            local subMenu = currentContext:getSubMenu(option.subOption)
            local target = logutils.GetOptionFromName(subMenu, name)

            if target then
                return target
            end
        end
    end

    return nil
end

-- ExecAfterTicks executes function fn after n ticks.
-- If n == 0 immediately executes fn.
-- If n < 0 does nothing.
-- Not supported args to callback function.
function logutils.ExecAfterTicks(fn, n)
    if n == 0 then
        fn()
        return
    elseif n < 0 then
        return
    end

    local c = 0
    local ticker = {}

    ticker.OnTick = function()
        c = c + 1

        if c == n then
            Events.OnTick.Remove(ticker.OnTick);

            fn();
        end
    end

    Events.OnTick.Add(ticker.OnTick);
end
