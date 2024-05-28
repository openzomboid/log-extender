--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--

local SafehouseClientLogger = {}

-- DumpSafehouse writes player's safehouse info to log file.
function SafehouseClientLogger.DumpSafehouse(player, action, safehouse, target)
    if player == nil then
        return nil;
    end

    local message = LogExtenderUtils.getLogLinePrefix(player, action);

    if safehouse then
        local area = {}
        local owner = player:getUsername()
        if action == "create safehouse" then
            owner = target
            target = nil
        end

        if instanceof(safehouse, 'SafeHouse') then
            owner = safehouse:getOwner();
            area = {
                Top = safehouse:getX() .. "x" .. safehouse:getY(),
                Bottom = safehouse:getX2() .. "x" .. safehouse:getY2(),
                zone = safehouse:getX() .. "," .. safehouse:getY() .. "," .. safehouse:getX2() - safehouse:getX() .. "," .. safehouse:getY2() - safehouse:getY()
            };
        end

        message = message .. ' ' .. area.zone
        message = message .. ' owner="' .. owner .. '"'

        if action == "release safehouse" then
            message = message .. ' members=['

            local members = safehouse:getPlayers();
            for j = 0, members:size() - 1 do
                local member = members:get(j)

                if member ~= owner then
                    message = message .. '"' .. member .. '"'
                    if j ~= members:size() - 1 then
                        message = message .. ','
                    end
                end
            end
            message = message .. ']'
        end
    else
        message = message .. ' ' .. '0,0,0,0' -- TODO: What can I do?
        message = message .. ' owner="' .. player:getUsername() .. '"'
    end

    if target ~= nil then
        message = message .. ' target="' .. target .. '"'
    end

    LogExtenderUtils.writeLog(LogExtenderUtils.filemask.safehouse, message);
end

-- OnTakeSafeHouse rewrites original ISWorldObjectContextMenu.onTakeSafeHouse and
-- adds logs for player take safehouse action.
SafehouseClientLogger.OnTakeSafeHouse = function()
    local originalOnTakeSafeHouse = ISWorldObjectContextMenu.onTakeSafeHouse;

    ISWorldObjectContextMenu.onTakeSafeHouse = function(worldobjects, square, player)
        originalOnTakeSafeHouse(worldobjects, square, player)

        local character = getSpecificPlayer(player)
        local safehouse = nil

        local safehouseList = SafeHouse.getSafehouseList();
        -- TODO: If player owned 2 or more safehouses we can get not relevant house.
        for i = 0, safehouseList:size() - 1 do
            if safehouseList:get(i):getOwner() == character:getUsername() then
                safehouse = safehouseList:get(i);
                break;
            end
        end

        SafehouseClientLogger.DumpSafehouse(character, "take safehouse", safehouse, nil)
    end
end

-- OnChangeSafeHouseOwner rewrites original ISSafehouseAddPlayerUI.onClick and
-- adds logs for change safehouse ownership action.
SafehouseClientLogger.OnChangeSafeHouseOwner = function()
    local onClickOriginal = ISSafehouseAddPlayerUI.onClick;

    ISSafehouseAddPlayerUI.onClick = function(self, button)
        local previousOwner = self.safehouse:getOwner()

        onClickOriginal(self, button)

        if button.internal == "ADDPLAYER" then
            if self.changeOwnership then
                local character = getPlayer()
                SafehouseClientLogger.DumpSafehouse(character, "change safehouse owner", self.safehouse, self.selectedPlayer)

                if previousOwner ~= character:getUsername() then
                    local message = character:getUsername() .. " change safehouse owner"
                            .. " at " .. LogExtenderUtils.getLocation(character)
                    LogExtenderUtils.writeLog(LogExtenderUtils.filemask.admin, message);
                end
            end
        end
    end
end

-- OnReleaseSafeHouse rewrites original ISSafehouseUI.onReleaseSafehouse and
-- adds logs for player release safehouse action.
SafehouseClientLogger.OnReleaseSafeHouse = function()
    local onReleaseSafehouseOriginal = ISSafehouseUI.onReleaseSafehouse;

    ISSafehouseUI.onReleaseSafehouse = function(self, button, player)
        if button.internal == "YES" then
            if button.parent.ui:isOwner() or button.parent.ui:hasPrivilegedAccessLevel() then
                local character = getPlayer()
                SafehouseClientLogger.DumpSafehouse(character, "release safehouse", button.parent.ui.safehouse, nil)
            end
        end

        onReleaseSafehouseOriginal(self, button, player)
    end
end

-- OnReleaseSafeHouseCommand rewrites original ISChat.onCommandEntered and
-- adds logs for player release safehouse action.
SafehouseClientLogger.OnReleaseSafeHouseCommand = function()
    local onCommandEnteredOriginal = ISChat.onCommandEntered;

    ISChat.onCommandEntered = function(self)
        local command = ISChat.instance.textEntry:getText();
        if command == "/releasesafehouse" then
            local character = getSpecificPlayer(0)
            local safehouse = nil

            local safehouseList = SafeHouse.getSafehouseList();
            -- TODO: If player owned 2 or more safehouses we can get not relevant house.
            for i = 0, safehouseList:size() - 1 do
                if safehouseList:get(i):getOwner() == character:getUsername() then
                    safehouse = safehouseList:get(i);
                    break;
                end
            end

            SafehouseClientLogger.DumpSafehouse(character, "release safehouse", safehouse, nil)
        end

        onCommandEnteredOriginal(self)
    end
end

-- OnRemovePlayerFromSafehouse rewrites original ISSafehouseUI.onRemovePlayerFromSafehouse
-- and adds logs for remove player from safehouse action.
SafehouseClientLogger.OnRemovePlayerFromSafehouse = function()
    local onRemovePlayerFromSafehouseOriginal = ISSafehouseUI.onRemovePlayerFromSafehouse;

    ISSafehouseUI.onRemovePlayerFromSafehouse = function(self, button, player)
        if button.internal == "YES" then
            local character = getPlayer()
            SafehouseClientLogger.DumpSafehouse(character, "remove player from safehouse", button.parent.ui.safehouse, button.parent.ui.selectedPlayer)
        end

        onRemovePlayerFromSafehouseOriginal(self, button, player)
    end
end

-- OnSendSafeHouseInvite rewrites original ISSafehouseAddPlayerUI.onClick and
-- adds logs for send safehouse invite action.
SafehouseClientLogger.OnSendSafeHouseInvite = function()
    local onClickOriginal = ISSafehouseAddPlayerUI.onClick;

    ISSafehouseAddPlayerUI.onClick = function(self, button)
        onClickOriginal(self, button)

        if button.internal == "ADDPLAYER" then
            if not self.changeOwnership then
                local character = getPlayer()
                SafehouseClientLogger.DumpSafehouse(character, "send safehouse invite", self.safehouse, self.selectedPlayer)
            end
        end
    end
end

-- OnJoinToSafehouse rewrites original ISSafehouseUI.onAnswerSafehouseInvite and
-- adds logs for players join to safehouse action.
SafehouseClientLogger.OnJoinToSafehouse = function()
    local onAnswerSafehouseInviteOriginal = ISSafehouseUI.onAnswerSafehouseInvite;

    ISSafehouseUI.onAnswerSafehouseInvite = function(self, button)
        if button.internal == "YES" then
            local character = getPlayer()
            SafehouseClientLogger.DumpSafehouse(character, "join to safehouse", button.parent.safehouse, nil)
        end

        onAnswerSafehouseInviteOriginal(self, button)
    end
end

--
-- Admin Tools
--

-- OnAddSafeHouse rewrites original ISWorldObjectContextMenu.onTakeSafeHouse and
-- adds logs for player take safehouse action.
SafehouseClientLogger.OnAddSafeHouse = function()
    local originalOnClick = ISAddSafeZoneUI.onClick;

    ISAddSafeZoneUI.onClick = function(self, button)
        originalOnClick(self, button)

        local setX = math.floor(math.min(self.X1, self.X2));
        local setY = math.floor(math.min(self.Y1, self.Y2));
        local setW = math.floor(math.abs(self.X1 - self.X2) + 1);
        local setH = math.floor(math.abs(self.Y1 - self.Y2) + 1);

        local character = getPlayer()
        local safehouse = nil

        local safehouseList = SafeHouse.getSafehouseList();
        for i = 0, safehouseList:size() - 1 do
            if safehouseList:get(i):getOwner() == self.ownerEntry:getInternalText() and safehouseList:get(i):getX() == setX and safehouseList:get(i):getY() == setY then
                safehouse = safehouseList:get(i);
                break;
            end
        end

        if SandboxVars.LogExtender.TakeSafeHouse then
            SafehouseClientLogger.DumpSafehouse(character, "create safehouse", safehouse, self.ownerEntry:getInternalText())
        end

        local message = character:getUsername() .. " create safehouse " .. tostring(setX) .. "," .. tostring(setY) .. "," .. tostring(setW) .. "," .. tostring(setH)
                .. " at " .. LogExtenderUtils.getLocation(character)
        LogExtenderUtils.writeLog(LogExtenderUtils.filemask.admin, message);
    end
end

if SandboxVars.LogExtender.TakeSafeHouse then
    SafehouseClientLogger.OnTakeSafeHouse()
end

if SandboxVars.LogExtender.ChangeSafeHouseOwner then
    SafehouseClientLogger.OnChangeSafeHouseOwner()
end

if SandboxVars.LogExtender.ReleaseSafeHouse then
    SafehouseClientLogger.OnReleaseSafeHouse()
end

if SandboxVars.LogExtender.RemovePlayerFromSafehouse then
    SafehouseClientLogger.OnRemovePlayerFromSafehouse()
end

if SandboxVars.LogExtender.SendSafeHouseInvite then
    SafehouseClientLogger.OnSendSafeHouseInvite()
end

if SandboxVars.LogExtender.JoinToSafehouse then
    SafehouseClientLogger.OnJoinToSafehouse()
end

if SandboxVars.LogExtender.ReleaseSafeHouse then
    SafehouseClientLogger.OnReleaseSafeHouseCommand()
end

LogExtenderClient.OnGameStart = function()
    if SandboxVars.LogExtender.SafehouseAdminTools then
        SafehouseClientLogger.OnAddSafeHouse()
    end
end

Events.OnGameStart.Add(LogExtenderClient.OnGameStart);
