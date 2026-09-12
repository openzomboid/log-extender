--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

if isClient() then return end

-- Fallback logger initialization if ConsoleLogger is not present in the global environment.
local logger = ConsoleLogger and ConsoleLogger.new() or {
    Debug = function(msg) print("ConsoleLogger DEBUG: " .. msg) end
}

local json = require "vendor/json/json"
local json_pretty_options = {pretty = true, indent = "  ", align_keys = false, array_newline = true}

local FactionsDumper = {
    factions = {}
}

-- WriteFile saves values to file in Zomboid/Lua directory.
function FactionsDumper.WriteFile(filename, data)
    local writer = getFileWriter(filename, true, false)
    if not writer then
        logger.Debug("FactionsDumper.WriteFile: no writer for file " .. filename)
        return false
    end

    if data ~= nil then
        local encodeddata = json:encode_pretty(data, nil, json_pretty_options)
        if encodeddata ~= nil then
            writer:write(encodeddata)
        end
    end

    logger.Debug("FactionsDumper.WriteFile: write to file ".. filename)
    writer:close()

    return true
end

function FactionsDumper.FillFactions()
    if SandboxVars.LogExtender.FactionsDumper == 0 then
        return
    end

    local factions = {}

    local factionList = Faction.getFactions()
    for i = 1, factionList:size() do
        local faction = factionList:get(i - 1)

        if instanceof(faction, 'Faction') then
            local key = faction:getOwner()

            local members = {}
            if faction:getPlayers() then
                for j = 0, faction:getPlayers():size() - 1 do
                    if faction:getOwner() ~= faction:getPlayers():get(j) then
                        table.insert(members, faction:getPlayers():get(j))
                    end
                end
            end

            factions[key] = {
                name    = faction:getName(),
                owner   = faction:getOwner(),
                tag     = faction:getTag(),
                members = members
            }
        end
    end

    logger.Debug("FactionsDumper.FillFactions: save " .. tostring(factionList:size()) .. " factions")

    FactionsDumper.WriteFile("factions.json", factions)
end

function FactionsDumper.OnServerStarted()
    local opt = SandboxVars.LogExtender.FactionsDumper

    if opt == 1 then
        return
    elseif opt == 2 then
        Events.EveryTenMinutes.Add(FactionsDumper.FillFactions)
    elseif opt == 3 then
        Events.EveryHours.Add(FactionsDumper.FillFactions)
    end

    FactionsDumper.FillFactions()
end

Events.OnServerStarted.Add(FactionsDumper.OnServerStarted)
