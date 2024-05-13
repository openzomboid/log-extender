--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- BrushToolLogger adds BrashTool logs to the Logs directory the Project Zomboid game.
--

require "LogExtenderClient"

BrushToolLogger = {
    filemask = {
        brush_tool = "brush_tool",
    },
    writeLog = LogExtenderClient.writeLog,
    getLogLinePrefix = LogExtenderClient.getLogLinePrefix,
    getLocation = LogExtenderClient.getLocation,
}

BrushToolLogger.doBrushToolOptions = function(player, context, worldobjects, test)
    if not SandboxVars.LogExtender.BrushToolLogs then
        return
    end

    if test and ISWorldObjectContextMenu.Test then return true end

    local character = getSpecificPlayer(player)
    local options = context:getMenuOptionNames()

    local destroyTileOption = context:getOptionFromName("Destroy tile")
    if destroyTileOption then
        local destroyTileMenu = context:getSubMenu(destroyTileOption.subOption)
        if destroyTileMenu then
            local m = destroyTileMenu
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BrushToolLogger.doBrushToolOptions);
