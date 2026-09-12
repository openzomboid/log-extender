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

local SafehousesDumper = {
    safehouses = {}
}

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
            writer:write(encodeddata)
        end
    end

    logger.Debug("SafehousesDumper.WriteFile: write to file ".. filename)
    writer:close()

    return true
end

-- FillSafehouses queries the global game world engine database to find safehouses and write them to file.
function SafehousesDumper.FillSafehouses()
    if SandboxVars.LogExtender.SafehousesDumper == 0 then
        return
    end

    local safehouses = {}

    local safehouseList = SafeHouse.getSafehouseList()
    for i = 1, safehouseList:size() do
        local safehouse = safehouseList:get(i - 1)

        if instanceof(safehouse, 'SafeHouse') then
            local key = tostring(safehouse:getX()) .. "," .. tostring(safehouse:getY()) .. "," .. tostring(safehouse:getW()) .. "," .. tostring(safehouse:getH())

            local members = {}
            if safehouse:getPlayers() then
                for j = 0, safehouse:getPlayers():size() - 1 do
                    if safehouse:getOwner() ~= safehouse:getPlayers():get(j) then
                        table.insert(members, safehouse:getPlayers():get(j))
                    end
                end
            end

            local formattedVisited = ""
            if safehouse:getLastVisited() and safehouse:getLastVisited() > 0 then
                formattedVisited = os.date("%Y-%m-%d %H:%M:%S", math.floor(safehouse:getLastVisited() / 1000))
            end

            safehouses[key] = {
                id         = safehouse:getId(),
                title      = safehouse:getTitle(),
                owner      = safehouse:getOwner(),
                created    = safehouse:getDatetimeCreated(),
                createdstr = safehouse:getDatetimeCreatedStr(),
                visited    = safehouse:getLastVisited(),
                visitedstr = formattedVisited,
                members    = members,
                location   = safehouse:getLocation(),
                x          = safehouse:getX(),
                y          = safehouse:getY(),
                w          = safehouse:getW(),
                h          = safehouse:getH()
            }
        end
    end

    logger.Debug("SafehousesDumper.FillSafehouses: save " .. tostring(safehouseList:size()) .. " safehouses")

    SafehousesDumper.WriteFile("safehouses.json", safehouses)
end

function SafehousesDumper.OnServerStarted()
    local opt = SandboxVars.LogExtender.SafehousesDumper

    if opt == 1 then
        return
    elseif opt == 2 then
        Events.EveryTenMinutes.Add(SafehousesDumper.FillSafehouses)
    elseif opt == 3 then
        Events.EveryHours.Add(SafehousesDumper.FillSafehouses)
    end

    SafehousesDumper.FillSafehouses()
end

Events.OnServerStarted.Add(SafehousesDumper.OnServerStarted)
