--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- BrushToolLogger adds BrushTool logs to the Logs directory the Project Zomboid game.
--

local BrushToolClientLogger = {}

function BrushToolClientLogger.onDestroyTile(obj)
    local character = getPlayer()
    local location = logutils.GetLocation(character);
    local objLocation = logutils.GetLocation(obj);
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

    local message = logutils.GetLogLinePrefix(character, "removed " .. objName) .. " (" .. texture .. ") at " .. objLocation .. " (" .. location .. ")";
    logutils.WriteLog(logutils.filemask.brushtool, message);
end

function BrushToolClientLogger.doBrushToolOptions(player, context, worldobjects, test)
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
                option.onSelect = BrushToolClientLogger.onDestroyTile
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BrushToolClientLogger.doBrushToolOptions);
