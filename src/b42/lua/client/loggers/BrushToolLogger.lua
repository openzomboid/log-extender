--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

-- Fallback logger initialization if ConsoleLogger is not present in the global environment.
local logger = ConsoleLogger and ConsoleLogger.new() or {
    Debug = function(msg) print("ConsoleLogger DEBUG: " .. msg) end
}

-- BrushToolLogger adds BrushTool logs to the Logs directory the Project Zomboid game.
local BrushToolLogger = {
    OriginalFunctions = {
        ISBrushToolTileCursor_create = nil -- ISBrushToolTileCursor.create is not exist on this time
    }
}

-- IsEnabledOnServer checks whether Brush Tool logging is enabled within the server sandbox configuration.
function BrushToolLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.BrushToolLogs
end

-- ISBrushToolTileCursor_create wraps the tile placement/creation method of the Brush Tool.
-- Adds log records to the brushtool.txt log file when objects are placed.
function BrushToolLogger.ISBrushToolTileCursor_create(self, x, y, z, north, sprite)
    BrushToolLogger.OriginalFunctions.ISBrushToolTileCursor_create(self, x, y, z, north, sprite)

    if not BrushToolLogger.IsEnabledOnServer() then
        return
    end

    local square = getCell():getGridSquare(x, y, z)
    local obj = IsoObject.new(square, sprite)

    local character = getPlayer()
    local location = logutils.GetLocation(character)
    local objLocation = logutils.GetLocation(obj)

    local objName = obj:getName() or obj:getObjectName() -- IsoObject
    if objName == "" then
        objName = instanceof(obj, 'IsoThumpable') and "IsoThumpable" or "undefined"
    end

    local message = logutils.GetLogLinePrefix(character, "added " .. objName) .. " (" .. sprite .. ") at " .. objLocation .. " (" .. location .. ")"
    logutils.WriteLog(logutils.filemask.brushtool, message)
end

-- onDestroyTile contains overridden select callback triggered when destroying a tile the
-- custom context menu hook. This is necessary because the original function "destroyTile"
-- is private and cannot be intercepted.
-- Adds log records to the brushtool.txt log file when objects are destroyed.
function BrushToolLogger.onDestroyTile(obj)
    local character = getPlayer()
    local location = logutils.GetLocation(character)
    local objLocation = logutils.GetLocation(obj)
    local texture = obj:getTextureName()
    local objName = obj:getName() or obj:getObjectName()
    if objName == "" then
        objName = instanceof(obj, 'IsoThumpable') and "IsoThumpable" or "undefined"
    end

    if isClient() then
        sledgeDestroy(obj)
    else
        obj:getSquare():transmitRemoveItemFromSquare(obj)
    end

    local message = logutils.GetLogLinePrefix(character, "removed " .. objName) .. " (" .. texture .. ") at " .. objLocation .. " (" .. location .. ")"
    logutils.WriteLog(logutils.filemask.brushtool, message)
end

-- doBrushToolOptions listens to context menu creation to intercept the 'Destroy tile' sub-options.
function BrushToolLogger.doBrushToolOptions(player, context, worldobjects, test)
    if not BrushToolLogger.IsEnabledOnServer() then
        return
    end

    if test and ISWorldObjectContextMenu.Test then return true end

    local destroyTileOption = logutils.GetOptionFromName(context, "Destroy tile")
    if destroyTileOption then
        local destroyTileMenu = context:getSubMenu(destroyTileOption.subOption)
        if destroyTileMenu then
            for i=1, #destroyTileMenu.options do
                local option = destroyTileMenu.options[i]
                option.onSelect = BrushToolLogger.onDestroyTile
            end
        end
    end
end

function BrushToolLogger.OnGameStart()
    if not ISBrushToolTileCursor then
        logger.Debug("BrushToolLogger: Brush Tool is not defined")

        return
    end

    BrushToolLogger.OriginalFunctions.ISBrushToolTileCursor_create = ISBrushToolTileCursor.create
    ISBrushToolTileCursor.create = BrushToolLogger.ISBrushToolTileCursor_create

    Events.OnFillWorldObjectContextMenu.Add(BrushToolLogger.doBrushToolOptions)
end

Events.OnGameStart.Add(BrushToolLogger.OnGameStart)
