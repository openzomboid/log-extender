--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- PVPClientLogger adds logr for PVP actions to the Logs directory the Project Zomboid game.
--

local PVPClientLogger = {}

-- WeaponHitCharacter adds player hit record to pvp log file.
-- [06-07-22 04:12:00.737] user Player1 (6823,5488,0) hit user Player2 (6822,5488,0) with Base.HuntingKnife damage 1.137.
PVPClientLogger.WeaponHitCharacter = function(attacker, target, weapon, damage)
    if not SandboxVars.LogExtender.HitPVP then
        return
    end

    if attacker ~= getPlayer() or not instanceof(target, 'IsoPlayer') then
        return
    end

    if target:isDead() then
        return
    end

    local message = 'user ' .. attacker:getUsername() .. ' (' .. logutils.GetLocation(attacker) ..  ') hit user ';
    message = message .. target:getUsername() .. ' (' .. logutils.GetLocation(target) ..  ') with ';
    message = message .. weapon:getFullType();
    message = message .. ' damage ' .. string.format("%.3f", damage);

    logutils.WriteLog(logutils.filemask.pvp, message);
end

-- OnGameStart adds callback for OnGameStart global event.
PVPClientLogger.OnGameStart = function()
    Events.OnWeaponHitCharacter.Add(PVPClientLogger.WeaponHitCharacter)
end

Events.OnGameStart.Add(PVPClientLogger.OnGameStart)
