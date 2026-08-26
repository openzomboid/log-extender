--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

local SafehouseLogger = {}

function SafehouseLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.SafehouseLogs
end

-- DumpSafehouse writes player's safehouse info to log file.
function SafehouseLogger.DumpSafehouse(character, action, safehouse, target)
    if character == nil then
        return nil
    end

    local message = logutils.GetLogLinePrefix(character, action)

    if safehouse then
        local area = {}
        local owner = character:getUsername()
        if action == "create safehouse" then
            owner = target
            target = nil
        end

        if instanceof(safehouse, 'SafeHouse') then
            owner = safehouse:getOwner()
            area = {
                Top = safehouse:getX() .. "x" .. safehouse:getY(),
                Bottom = safehouse:getX2() .. "x" .. safehouse:getY2(),
                zone = safehouse:getX() .. "," .. safehouse:getY() .. "," .. safehouse:getX2() - safehouse:getX() .. "," .. safehouse:getY2() - safehouse:getY()
            }
        end

        message = message .. ' ' .. area.zone
        message = message .. ' owner="' .. owner .. '"'

        if action == "release safehouse" then
            message = message .. ' members=['

            local members = safehouse:getPlayers()
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
        message = message .. ' owner="' .. character:getUsername() .. '"'
    end

    if target ~= nil then
        message = message .. ' target="' .. target .. '"'
    end

    message = message .. " (" .. logutils.GetLocation(character) .. ")"

    logutils.WriteLog(logutils.filemask.safehouse, message)
end

-- OnTakeSafeHouse rewrites original ISWorldObjectContextMenu.onTakeSafeHouse and
-- adds logs for player take safehouse action.
function SafehouseLogger.OnTakeSafeHouse()
    local originalOnTakeSafeHouse = ISWorldObjectContextMenu.onTakeSafeHouse

    ISWorldObjectContextMenu.onTakeSafeHouse = function(worldobjects, square, player)
        originalOnTakeSafeHouse(worldobjects, square, player)

        logutils.ExecAfterTicks(function()
            local character = getSpecificPlayer(player)
            local safehouse = nil

            local safehouseList = SafeHouse.getSafehouseList();
            for i = 0, safehouseList:size() - 1 do
                if safehouseList:get(i):getOwner() == character:getUsername() and safehouseList:get(i):getTitle() == character:getUsername() then
                    safehouse = safehouseList:get(i)
                    break
                end
            end

            SafehouseLogger.DumpSafehouse(character, "take safehouse", safehouse, nil)
        end, 10)
    end
end

-- OnChangeSafeHouseOwner rewrites original ISSafehouseAddPlayerUI.onClick and
-- adds logs for change safehouse ownership action.
function SafehouseLogger.OnChangeSafeHouseOwner()
    local onClickOriginal = ISSafehouseAddPlayerUI.onClick

    ISSafehouseAddPlayerUI.onClick = function(self, button)
        local owner = self.safehouse:getOwner()

        onClickOriginal(self, button)

        if button.internal == "ADDPLAYER" then
            local character = getPlayer()

            if self.changeOwnership then
                SafehouseLogger.DumpSafehouse(character, "change safehouse owner", self.safehouse, self.selectedPlayer)
            else
                SafehouseLogger.DumpSafehouse(character, "add player to safehouse", self.safehouse, self.selectedPlayer)
            end

            if owner ~= character:getUsername() then
                local message = character:getUsername() .. " change safehouse " .. logutils.GetSafehouseShortNotation(self.safehouse) .. " at " .. logutils.GetLocation(character)
                logutils.WriteLog(logutils.filemask.admin, message)
            end
        end
    end
end

-- OnReleaseSafeHouse rewrites original ISSafehouseUI.onReleaseSafehouse and
-- adds logs for player release safehouse action.
function SafehouseLogger.OnReleaseSafeHouse()
    local onReleaseSafehouseOriginal = ISSafehouseUI.onReleaseSafehouse

    ISSafehouseUI.onReleaseSafehouse = function(self, button, player)
        local owner = button.parent.ui.safehouse:getOwner()

        if button.internal == "YES" then
            if button.parent.ui:isOwner() or button.parent.ui:hasPrivilegedAccessLevel() then
                local character = getPlayer()
                SafehouseLogger.DumpSafehouse(character, "release safehouse", button.parent.ui.safehouse, nil)

                if owner ~= character:getUsername() then
                    local message = character:getUsername() .. " release safehouse " .. logutils.GetSafehouseShortNotation(button.parent.ui.safehouse) .. " at " .. logutils.GetLocation(character)
                    logutils.WriteLog(logutils.filemask.admin, message)
                end
            end
        end

        onReleaseSafehouseOriginal(self, button, player)
    end
end

-- OnReleaseSafeHouseCommand rewrites original ISChat.onCommandEntered and
-- adds logs for player release safehouse action.
function SafehouseLogger.OnReleaseSafeHouseCommand()
    local onCommandEnteredOriginal = ISChat.onCommandEntered

    ISChat.onCommandEntered = function(self)
        local command = ISChat.instance.textEntry:getText()

        if string.find(command, "/releasesafehouse", 1, true) then
            local character = getSpecificPlayer(0)
            local safehouse = nil

            local title = command:gsub("/releasesafehouse ", "", 1):gsub('"', "")

            local safehouseList = SafeHouse.getSafehouseList();
            for i = 0, safehouseList:size() - 1 do
                -- TODO Add checking removing by admin
                if safehouseList:get(i):getOwner() == character:getUsername() and safehouseList:get(i):getTitle() == title then
                    safehouse = safehouseList:get(i)
                    break
                end
            end

            SafehouseLogger.DumpSafehouse(character, "release safehouse", safehouse, nil)
        end

        onCommandEnteredOriginal(self)
    end
end

-- OnRemovePlayerFromSafehouse rewrites original ISSafehouseUI.onRemovePlayerFromSafehouse
-- and adds logs for remove player from safehouse action.
function SafehouseLogger.OnRemovePlayerFromSafehouse()
    local onRemovePlayerFromSafehouseOriginal = ISSafehouseUI.onRemovePlayerFromSafehouse

    ISSafehouseUI.onRemovePlayerFromSafehouse = function(self, button, player)
        if button.internal == "YES" then
            local character = getPlayer()
            SafehouseLogger.DumpSafehouse(character, "remove player from safehouse", button.parent.ui.safehouse, button.parent.ui.selectedPlayer)
        end

        onRemovePlayerFromSafehouseOriginal(self, button, player)
    end
end

-- OnSendSafeHouseInvite rewrites original ISSafehouseAddPlayerUI.onClick and
-- adds logs for send safehouse invite action.
function SafehouseLogger.OnSendSafeHouseInvite()
    local onClickOriginal = ISSafehouseAddPlayerUI.onClick

    ISSafehouseAddPlayerUI.onClick = function(self, button)
        onClickOriginal(self, button)

        if button.internal == "ADDPLAYER" then
            if not self.changeOwnership then
                local character = getPlayer()
                SafehouseLogger.DumpSafehouse(character, "send safehouse invite", self.safehouse, self.selectedPlayer)
            end
        end
    end
end

-- OnJoinToSafehouse rewrites original ISSafehouseUI.onAnswerSafehouseInvite and
-- adds logs for players join to safehouse action.
function SafehouseLogger.OnJoinToSafehouse()
    local onAnswerSafehouseInviteOriginal = ISSafehouseUI.onAnswerSafehouseInvite

    ISSafehouseUI.onAnswerSafehouseInvite = function(self, button)
        if button.internal == "YES" then
            local character = getPlayer()
            SafehouseLogger.DumpSafehouse(character, "join to safehouse", button.parent.safehouse, nil)
        end

        onAnswerSafehouseInviteOriginal(self, button)
    end
end

if SafehouseLogger.IsEnabledOnServer() then
    SafehouseLogger.OnTakeSafeHouse()
    SafehouseLogger.OnChangeSafeHouseOwner()
    SafehouseLogger.OnReleaseSafeHouse()
    SafehouseLogger.OnRemovePlayerFromSafehouse()
    SafehouseLogger.OnSendSafeHouseInvite()
    SafehouseLogger.OnJoinToSafehouse()
    SafehouseLogger.OnReleaseSafeHouseCommand()
end

--
-- Admin Tools
--

-- OnAdminAddSafeHouse rewrites original ISWorldObjectContextMenu.onTakeSafeHouse and
-- adds logs for player take safehouse action.
SafehouseLogger.OnAdminAddSafeHouse = function()
    local originalOnClick = ISAddSafeZoneUI.onClick

    ISAddSafeZoneUI.onClick = function(self, button)
        originalOnClick(self, button)

        local setX = math.floor(math.min(self.X1, self.X2))
        local setY = math.floor(math.min(self.Y1, self.Y2))
        local setW = math.floor(math.abs(self.X1 - self.X2) + 1)
        local setH = math.floor(math.abs(self.Y1 - self.Y2) + 1)

        local character = getPlayer()
        local safehouse = nil

        local safehouseList = SafeHouse.getSafehouseList()
        for i = 0, safehouseList:size() - 1 do
            if safehouseList:get(i):getOwner() == self.ownerEntry:getInternalText() and safehouseList:get(i):getX() == setX and safehouseList:get(i):getY() == setY then
                safehouse = safehouseList:get(i)
                break
            end
        end

        if SafehouseLogger.IsEnabledOnServer() then
            SafehouseLogger.DumpSafehouse(character, "create safehouse", safehouse, self.ownerEntry:getInternalText())
        end

        local message = character:getUsername() .. " create safehouse " .. tostring(setX) .. "," .. tostring(setY) .. "," .. tostring(setW) .. "," .. tostring(setH) .. " at " .. logutils.GetLocation(character)
        logutils.WriteLog(logutils.filemask.admin, message)
    end
end

function SafehouseLogger.OnGameStart()
    if SandboxVars.LogExtender.SafehouseAdminTools then
        SafehouseLogger.OnAdminAddSafeHouse()
    end
end

Events.OnGameStart.Add(SafehouseLogger.OnGameStart)
