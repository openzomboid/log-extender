--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--

logutils = {
    version = "0.12.0", -- in semantic versioning (http://semver.org/)

    -- Placeholders for Project Zomboid log file names.
    -- Project Zomboid generates files like this 24-08-19_18-11_chat.txt
    -- at first action and use file until next server restart.
    filemask = {
        chat = "chat",
        user = "user",
        cmd = "cmd",
        item = "item",
        map = "map",
        pvp = "pvp",
        vehicle = "vehicle",
        player = "player",
        admin = "admin",
        safehouse = "safehouse",
        craft = "craft",
        map_alternative = "map_alternative",
        brushtool = "brushtool",
    },
}

-- WriteLog sends command to server for writting log line to file.
function logutils.WriteLog(filemask, message)
    sendClientCommand("LogExtender", "write", { mask = filemask, message = message });
end

-- GetLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
function logutils.GetLogLinePrefix(player, action)
    -- TODO: Add ownerID.
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
end

-- GetLocation returns players or vehicle location in "x,x,z" format.
function logutils.GetLocation(obj)
    return math.floor(obj:getX()) .. "," .. math.floor(obj:getY()) .. "," .. math.floor(obj:getZ());
end

-- GetPlayerSafehouses iterates in server safehouse list and returns
-- area coordinates of player's houses.
function logutils.GetPlayerSafehouses(player)
    if player == nil then
        return nil;
    end

    local safehouses = {
        Owner = {},
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
            safehouses.Owner[#safehouses.Owner + 1] = area;
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

-- GetPlayerPerks returns player perks table.
function logutils.GetPlayerPerks(player)
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

-- GetPlayerTraits returns player traits table.
function logutils.GetPlayerTraits(player)
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

-- GetPlayerStats returns some player additional info.
function logutils.GetPlayerStats(player)
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

-- GetPlayerHealth returns some player health information.
function logutils.GetPlayerHealth(player)
    if player == nil then
        return nil;
    end

    local bd = player:getBodyDamage()

    local health = {}

    health.Health = math.floor(bd:getOverallBodyHealth());
    health.Infected = bd:IsInfected() and "true" or "false";

    return health;
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
    info.Center = logutils.GetLocation(vehicle:getCurrentSquare());

    return info;
end

function logutils.GetSafehouseShrotNotation(safehouse)
    if not safehouse then
        return "0,0,0,0"
    end

    local x = math.floor(math.min(safehouse:getX(), safehouse:getX2()));
    local y = math.floor(math.min(safehouse:getY(), safehouse:getY2()));
    local w = math.floor(math.abs(safehouse:getX() - safehouse:getX2()));
    local h = math.floor(math.abs(safehouse:getY() - safehouse:getY2()));

    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(w) .. "," .. tostring(h)
end
