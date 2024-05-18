--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- BrushToolLogger adds BrushTool logs to the Logs directory the Project Zomboid game.
--

local BrushToolLoggerServer = {
    Original = {
        ISBrushToolTileCursor_create = ISBrushToolTileCursor.create
    }
}

function BrushToolLoggerServer.createBrushToolTileCursor(self, x, y, z, north, sprite)
    BrushToolLoggerServer.Original.ISBrushToolTileCursor_create(self, x, y, z, north, sprite)

    if not SandboxVars.LogExtender.BrushToolLogs then
        return
    end

    local character = getPlayer()
    local location = LogExtenderUtils.getLocation(character);
    local objLocation = tostring(x) .. ',' .. tostring(y) .. ',' .. tostring(y);
    local texture = sprite
    local objName = "IsoThumpable"

    local message = LogExtenderUtils.getLogLinePrefix(character, "added " .. objName) .. " (" .. texture .. ") at " .. objLocation .. " (" .. location .. ")";
    LogExtenderUtils.writeLog(LogExtenderUtils.filemask.brushtool, message);
end

ISBrushToolTileCursor.create = BrushToolLoggerServer.createBrushToolTileCursor;
