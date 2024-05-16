--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- BrushToolLogger adds BrashTool logs to the Logs directory the Project Zomboid game.
--

require "LogExtenderClient"

local BrushToolLogger = {
    filemask = {
        brush_tool = "brushtool",
    },
    writeLog = LogExtenderClient.writeLog,
    getLogLinePrefix = LogExtenderClient.getLogLinePrefix,
    getLocation = LogExtenderClient.getLocation,
}

function BrushToolLogger.OnDestroyTile(obj)
    local character = getPlayer()
    local location = LogExtenderClient.getLocation(character);
    local objLocation = LogExtenderClient.getLocation(obj);
    local texture = obj:getTextureName()
    local objName = obj:getName() or obj:getObjectName();
    if objName == "" then
        objName = instanceof(obj, 'IsoThumpable') and "IsoThumpable" or "undefined"
    end

    if isClient() then
        sledgeDestroy(obj)
    else
        obj:getSquare():transmitRemoveItemFromSquare(obj)
    end

    local message = LogExtenderClient.getLogLinePrefix(character, "removed " .. objName) .. " (" .. texture .. ") at " .. objLocation .. " (" .. location .. ")";
    LogExtenderClient.writeLog(BrushToolLogger.filemask.brush_tool, message);
end

function BrushToolLogger.doBrushToolOptions(player, context, worldobjects, test)
    if not SandboxVars.LogExtender.BrushToolLogs then
        return
    end

    if test and ISWorldObjectContextMenu.Test then return true end

    local destroyTileOption = context:getOptionFromName("Destroy tile")
    if destroyTileOption then
        local destroyTileMenu = context:getSubMenu(destroyTileOption.subOption)
        if destroyTileMenu then
            for i=1, #destroyTileMenu.options do
                local option = destroyTileMenu.options[i];
                option.onSelect = BrushToolLogger.OnDestroyTile
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BrushToolLogger.doBrushToolOptions);
