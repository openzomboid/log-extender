--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- AlternativeMapClientLogger adds alternalive logs for map actions to the Logs directory
-- the Project Zomboid game.
--

-- TODO: Move here logs from TimedActionsClientLogger.

local AlternativeMapClientLogger = {}

-- WeaponHitThumpable adds objects hit record to map_alternative log file.
-- [12-12-22 07:08:28.916] 76561190000000000 "outdead" destroyed IsoObject (location_restaurant_spiffos_02_25) with Base.Axe at 11633,8265,0 (11633,8265,0).
-- TODO: Make me work.
AlternativeMapClientLogger.WeaponHitThumpable = function(character, weapon, object)
    if not SandboxVars.LogExtender.AlternativeMap then
        return
    end

    if character ~= getPlayer() then
        return
    end

    local location = logutils.GetLocation(character);

    local objLocation = logutils.GetLocation(object);
    local sprite = object:getSprite();
    local spriteName = sprite:getName() or "undefined"
    local objName = object:getName() or object:getObjectName();

    local message = logutils.GetLogLinePrefix(character, "destroyed " .. objName) .. " (" .. spriteName .. ") with " .. weapon:getName() .. " at " .. objLocation .. " (" .. location .. ")";
    logutils.WriteLog(logutils.filemask.map_alternative, message);
end

Events.OnWeaponHitThumpable.Add(AlternativeMapClientLogger.WeaponHitThumpable)
