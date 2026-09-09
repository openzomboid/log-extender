--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

-- Fallback logger initialization if ConsoleLogger is not present in the global environment.
local logger = ConsoleLogger and ConsoleLogger.new() or {
    Debug = function(msg) print("ConsoleLogger DEBUG: " .. msg) end
}

if isClient() then logger.Debug("SafehousesDumper called from client"); return end

local SafehousesDumper = {
    safehouses = {}
}

local json = require "vendor/json/json"
local json_pretty_options = {pretty = true, indent = "  ", align_keys = false, array_newline = true}

-- WriteFile saves values to file in Zomboid/Lua directory.
function SafehousesDumper.WriteFile(filename, data)
    local writer = getFileWriter(filename, true, false)
    if not writer then
        logger.Debug("SafehousesDumper.WriteFile: no writer for file " .. filename)
        return false
    end

    if data ~= nil then
        local encodeddata = json:encode_pretty(data, nil, json_pretty_options)
        if encodeddata ~= nil then
            logger.Debug("SafehousesDumper.WriteFile: write to file".. filename)
            writer:write(encodeddata)
        end
    end

    logger.Debug("SafehousesDumper.WriteFile: close file ".. filename)
    writer:close()

    return true
end

-- FillSafehouses queries the global game world engine database to find safehouses and write them to file.
function SafehousesDumper.FillSafehouses()
    if not SandboxVars.LogExtender.SafehousesDumper then
        logger.Debug("SafehousesDumper.FillSafehouses: Not enabled on server")

        return
    end

    logger.Debug("SafehousesDumper.FillSafehouses: tick")

    local safehouses = {}

    local safehouseList = SafeHouse.getSafehouseList()
    for i = 1, safehouseList:size() do
        local safehouse = safehouseList:get(i - 1)

        if instanceof(safehouse, 'SafeHouse') then
            logger.Debug("SafehousesDumper.FillSafehouses: valid safehouse")

            local members = {}
            if safehouse:getPlayers() then
                for j = 0, safehouse:getPlayers():size() - 1 do
                    if safehouse:getOwner() ~= safehouse:getPlayers():get(j) then
                        table.insert(members, safehouse:getPlayers():get(j))
                    end
                end
            end

            local key = tostring(safehouse:getX()) .. "," .. tostring(safehouse:getY()) .. "," .. tostring(safehouse:getW()) .. "," .. tostring(safehouse:getH())

            safehouses[key] = {
                id       = safehouse:getId(),
                title    = safehouse:getTitle(),
                owner    = safehouse:getOwner(),
                created  = safehouse:getDatetimeCreated(),
                --created  = safehouse:getDatetimeCreatedStr(),
                visited  = safehouse:getLastVisited(),
                members  = members,
                location = safehouse:getLocation(),
                x        = safehouse:getX(),
                y        = safehouse:getY(),
                w        = safehouse:getW(),
                h        = safehouse:getH()
            }
        end
    end

    logger.Debug("SafehousesDumper.FillSafehouses: save")

    SafehousesDumper.WriteFile("safehouses.json", safehouses)
end

function SafehousesDumper.OnServerStarted()
    logger.Debug("SafehousesDumper.OnServerStarted")

    SafehousesDumper.FillSafehouses()

    --Events.EveryOneMinute.Add(SafehousesDumper.FillSafehouses)
    --Events.EveryTenMinutes.Add(SafehousesDumper.FillSafehouses)
    Events.EveryHours.Add(SafehousesDumper.FillSafehouses)
end

Events.OnServerStarted.Add(SafehousesDumper.OnServerStarted)
