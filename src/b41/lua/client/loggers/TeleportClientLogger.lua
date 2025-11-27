--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- TeleportClientLogger adds logr for teleport actions to the Logs directory
-- the Project Zomboid game.
--

local TeleportClientLogger = {}

-- OnTeleport adds logs for teleport actions.
TeleportClientLogger.OnTeleport = function()
    local originalOnTeleportValid = DebugContextMenu.onTeleportValid;
    local originalISSafehousesListOnClick = ISSafehousesList.onClick;
    local originalISMiniMapInnerOnTeleport = ISMiniMapInner.onTeleport;
    local originalISWorldMapOnTeleport = ISWorldMap.onTeleport;

    DebugContextMenu.onTeleportValid = function(button, x, y, z)
        originalOnTeleportValid(button, x, y, z);

        local message = getPlayer():getUsername() .. " teleported to " .. x .. "," .. y .. "," .. z
        logutils.WriteLog(logutils.filemask.admin, message);
    end

    ISSafehousesList.onClick = function(self, button)
        originalISSafehousesListOnClick(self, button);

        if button.internal == "TELEPORT" then
            local message = getPlayer():getUsername() .. " teleported to " .. self.selectedSafehouse:getX() .. "," .. self.selectedSafehouse:getY() .. "," .. 0
            logutils.WriteLog(logutils.filemask.admin, message);
        end
    end

    ISMiniMapInner.onTeleport = function(self, worldX, worldY)
        originalISMiniMapInnerOnTeleport(self, worldX, worldY)

        local message = getPlayer():getUsername() .. " teleported to " .. math.floor(worldX) .. "," .. math.floor(worldY) .. "," .. 0
        logutils.WriteLog(logutils.filemask.admin, message);
    end

    ISWorldMap.onTeleport = function(self, worldX, worldY)
        originalISWorldMapOnTeleport(self, worldX, worldY)

        local message = getPlayer():getUsername() .. " teleported to " .. math.floor(worldX) .. "," .. math.floor(worldY) .. "," .. 0
        logutils.WriteLog(logutils.filemask.admin, message);
    end
end

-- OnGameStart adds callback for OnGameStart global event.
TeleportClientLogger.OnGameStart = function()
    if SandboxVars.LogExtender.AdminTeleport then
        TeleportClientLogger.OnTeleport()
    end
end

Events.OnGameStart.Add(TeleportClientLogger.OnGameStart)
