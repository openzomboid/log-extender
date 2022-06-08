--
-- Copyright (c) 2022 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- LogExtenderClient adds more logs to the Logs directory the Project Zomboid game.
--

-- TODO: Create JSON marshaller.

local version = "0.9.0"

local pzversion = getCore():getVersionNumber()

LogExtenderClient = {
    version = version,

    -- Placeholders for Project Zomboid log file names.
    -- Project Zomboid generates files like this 24-08-19_18-11_chat.txt
    -- at first action and use file until next server restart.
    filemask = {
        chat = "chat",
        user = "user",
        cmd = "cmd",
        vehicle = "vehicle",
        player = "player",
        item = "item",
        map = "map",
        admin = "admin",
        safehouse = "safehouse",
    },

    -- Store ingame player object when user is logged in.
    player = nil,
    -- Store vehicle object when user enter to it.
    vehicle = nil,
    -- Store vehicle object when user attach it.
    vehicleAttachment = nil,
}

LogExtenderClient.writeLog = function(filemask, message)
    sendClientCommand("LogExtender", "write", { mask = filemask, message = message });
end

-- getLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
LogExtenderClient.getLogLinePrefix = function(player, action)
    -- TODO: Add ownerID.
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
end

-- getLocation returns players or vehicle location in "x,x,z" format.
LogExtenderClient.getLocation = function(obj)
    return math.floor(obj:getX()) .. "," .. math.floor(obj:getY()) .. "," .. math.floor(obj:getZ());
end

-- getPlayerSafehouse iterates in server safehouse list and returns
-- area coordinates of player's houses.
LogExtenderClient.getPlayerSafehouses = function(player)
    if player == nil then
        return nil;
    end

    local safehouses = {
        Owner = nil,
        Member = {}
    };

    local safehouseList = SafeHouse.getSafehouseList();
    for i = 0, safehouseList:size() - 1 do
        local safehouse = safehouseList:get(i);
        local owner = safehouse:getOwner();
        local members = safehouse:getPlayers();
        local area = {
            Top = safehouse:getX() .. "x" .. safehouse:getY(),
            Bottom = safehouse:getX2() .. "x" .. safehouse:getY2()
        };

        if player:getUsername() == owner then
            safehouses.Owner = area;
        elseif members:size() > 0 then
            for j = 0, members:size() - 1 do
                if members:get(j) == player:getUsername() then
                    safehouses.Member[#safehouses.Member + 1] = area;
                    break;
                end
            end
        end
    end

    return safehouses;
end

-- getPlayerPerks returns player perks table.
LogExtenderClient.getPlayerPerks = function(player)
    if player == nil then
        return nil;
    end

    local perks = {}

    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i));

        if perk then
            local parent = perk:getParent();
            if parent ~= Perks.None then
                local perkType = tostring(perk:getType());
                local perkLevel = player:getPerkLevel(Perks.fromIndex(i));
                local key = "\"" .. perkType .. "\"";

                table.insert(perks, key .. ":" .. perkLevel);
            end
        end
    end

    table.sort(perks);

    return perks;
end

-- getPlayerTraits returns player traits table.
LogExtenderClient.getPlayerTraits = function(player)
    if player == nil then
        return nil;
    end

    local traits = {}

    for i=0, player:getTraits():size() - 1 do
        local trait = TraitFactory.getTrait(player:getTraits():get(i));

        if trait then
            table.insert(traits, '"' .. trait:getType() .. '"');
        end
    end

    table.sort(traits);

    return traits;
end

-- getPlayerStats returns some player additional info.
LogExtenderClient.getPlayerStats = function(player)
    if player == nil then
        return nil;
    end

    local stats = {}

    stats.Kills = player:getZombieKills();
    stats.Survived = math.floor(player:getHoursSurvived() * 100) / 100;
    stats.Profession = "";

    if player:getDescriptor() and player:getDescriptor():getProfession() then
        local prof = ProfessionFactory.getProfession(player:getDescriptor():getProfession());
        if prof then
            stats.Profession = prof:getType();
        end
    end

    return stats;
end

-- getPlayerHealth returns some player health information.
LogExtenderClient.getPlayerHealth = function(player)
    if player == nil then
        return nil;
    end

    local bd = player:getBodyDamage()

    local health = {}

    health.Health = math.floor(bd:getOverallBodyHealth());
    health.Infected = bd:IsInfected() and "true" or "false";

    return health;
end

-- getVehicleInfo returns some vehicles information such as id, type and center
-- coordinate.
LogExtenderClient.getVehicleInfo = function(vehicle)
    local info = {
        ID = "0",
        Type = "unknown",
        Center = "10,10,0", -- Unexisting coordinate.
    }

    if vehicle == nil then
        return info;
    end

    local id = vehicle:getID() or "0";
    local type = "unknown";

    local script = vehicle:getScript();
    if script then
        type = script:getName() or "unknown";
    end;

    info.ID = tostring(id);
    info.Type = type;
    info.Center = LogExtenderClient.getLocation(vehicle:getCurrentSquare());

    return info;
end

-- DumpPlayer writes player perks and safehouse coordinates to log file.
LogExtenderClient.DumpPlayer = function(player, action)
    if player == nil then
        return nil;
    end

    local message = LogExtenderClient.getLogLinePrefix(player, action);

    local perks = LogExtenderClient.getPlayerPerks(player);
    if perks ~= nil then
        message = message .. " perks={" .. table.concat(perks, ",") .. "}";
    else
        message = message .. " perks={}";
    end

    local traits = LogExtenderClient.getPlayerTraits(player);
    if traits ~= nil then
        message = message .. " traits=[" .. table.concat(traits, ",") .. "]";
    else
        message = message .. " traits=[]";
    end

    local stats = LogExtenderClient.getPlayerStats(player);
    if stats ~= nil then
        message = message .. ' stats={'
                .. '"profession":"' .. stats.Profession .. '",'
                .. '"kills":' .. stats.Kills .. ','
                .. '"hours":' .. stats.Survived
                .. '}';
    else
        message = message .. " stats={}";
    end

    local health = LogExtenderClient.getPlayerHealth(player)
    if health ~= nil then
        message = message .. ' health={'
                .. '"health":' .. health.Health .. ','
                .. '"infected":' .. health.Infected
                .. '}';
    else
        message = message .. " health={}";
    end

    local safehouses = LogExtenderClient.getPlayerSafehouses(player);
    if safehouses ~= nil then
        message = message .. " safehouse owner=("
        if safehouses.Owner ~= nil then
            message = message .. safehouses.Owner.Top .. " - " .. safehouses.Owner.Bottom;
        end
        message = message .. ")";

        message = message .. " safehouse member=(";
        if #safehouses.Member > 0 then
            local temp = ""

            for i = 1, #safehouses.Member do
                local area = safehouses.Member[i];
                temp = temp .. area.Top .. " - " .. area.Bottom;
                if i ~= #safehouses.Member then
                    temp = temp .. ", ";
                end
            end

            message = message .. temp;
        end
        message = message .. ")"
    else
        message = message .. " safehouse owner=() safehouse member=()"
    end

    local location = LogExtenderClient.getLocation(player);
    message = message .. " (" .. location .. ")"

    LogExtenderClient.writeLog(LogExtenderClient.filemask.player, message);
end

-- DumpVehicle writes vehicles info to log file.
LogExtenderClient.DumpVehicle = function(player, action, vehicle, vehicle2)
    if player == nil then
        return nil;
    end

    local message = LogExtenderClient.getLogLinePrefix(player, action);

    if vehicle then
        local info = LogExtenderClient.getVehicleInfo(vehicle)

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}';
    else
        message = message .. " vehicle={}";
    end

    if vehicle2 then
        local info = LogExtenderClient.getVehicleInfo(vehicle2)

        if action == 'attach' then
            message = message .. ' to'
        elseif action == 'detach' then
            message = message .. ' from'
        end

        message = message .. ' vehicle={'
                .. '"id":' .. info.ID .. ','
                .. '"type":"' .. info.Type .. '",'
                .. '"center":"' .. info.Center .. '"'
                .. '}';
    end

    local location = LogExtenderClient.getLocation(player);
    message = message .. " at " .. location

    LogExtenderClient.writeLog(LogExtenderClient.filemask.vehicle, message);
end

-- DumpSafehouse writes player's safehouse info to log file.
LogExtenderClient.DumpSafehouse = function(player, action, safehouse, target)
    if player == nil then
        return nil;
    end

    local message = LogExtenderClient.getLogLinePrefix(player, action);

    if safehouse then
        local area = {}
        local owner = player:getUsername()

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

    --local location = LogExtenderClient.getLocation(player);
    --message = message .. " @ " .. location

    LogExtenderClient.writeLog(LogExtenderClient.filemask.safehouse, message);
end

-- DumpAdminItem writes admin actions with items.
LogExtenderClient.DumpAdminItem = function(player, action, itemName, count, target)
    if player == nil then
        return nil;
    end

    local message = player:getUsername() .. " " .. action

    message = message .. " " .. count .. " " .. itemName
    message = message .. " in " .. target:getUsername() .. "'s"
    message = message .. " inventory"

    LogExtenderClient.writeLog(LogExtenderClient.filemask.admin, message);
end

-- TimedActionPerform overrides the original ISBaseTimedAction: perform function to gain
-- access to player events.
LogExtenderClient.TimedActionPerform = function()
    local originalPerform = ISBaseTimedAction.perform;

    ISBaseTimedAction.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player and self.Type then
            local location = LogExtenderClient.getLocation(player);

            if self.Type == "ISTakeGenerator" then
                local message = LogExtenderClient.getLogLinePrefix(player, "taken IsoGenerator") .. " (appliances_misc_01_0) at " .. location;
                LogExtenderClient.writeLog(LogExtenderClient.filemask.map, message);
            elseif self.Type == "ISToggleStoveAction" then
                local message = LogExtenderClient.getLogLinePrefix(player, "stove.toggle") .. " @ " .. location;
                LogExtenderClient.writeLog(LogExtenderClient.filemask.cmd, message);
            elseif self.Type == "ISPlaceCampfireAction" then
                local message = LogExtenderClient.getLogLinePrefix(player, "added Campfire") .. " (camping_01_6) at " .. location;
                LogExtenderClient.writeLog(LogExtenderClient.filemask.map, message);
            elseif self.Type == "ISRemoveCampfireAction" then
                local message = LogExtenderClient.getLogLinePrefix(player, "taken Campfire") .. " (camping_01_6) at " .. location;
                LogExtenderClient.writeLog(LogExtenderClient.filemask.map, message);
            elseif (self.Type == "ISLightFromKindle" or self.Type == "ISLightFromLiterature" or self.Type == "ISLightFromPetrol") then
                local message = LogExtenderClient.getLogLinePrefix(player, "campfire.light") .. " @ " .. location;
                LogExtenderClient.writeLog(LogExtenderClient.filemask.cmd, message);
            elseif self.Type == "ISPutOutCampfireAction" then
                local message = LogExtenderClient.getLogLinePrefix(player, "campfire.extinguish") .. " @ " .. location;
                LogExtenderClient.writeLog(LogExtenderClient.filemask.cmd, message);
            end;
        end;
    end;
end

-- OnTakeSafeHouse rewrites original ISWorldObjectContextMenu.onTakeSafeHouse and
-- adds logs for player take safehouse action.
LogExtenderClient.OnTakeSafeHouse = function()
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

        LogExtenderClient.DumpSafehouse(character, "take safehouse", safehouse, nil)
    end
end

-- OnReleaseSafeHouse rewrites original ISSafehouseUI.onClick and
-- adds logs for player release safehouse action.
LogExtenderClient.OnReleaseSafeHouse = function()
    local onClickOriginal = ISSafehouseUI.onClick;

    ISSafehouseUI.onClick = function(self, button)
        onClickOriginal(self, button)

        if button.internal == "RELEASE" then
            local character = getPlayerFromUsername(self.safehouse:getOwner())
            LogExtenderClient.DumpSafehouse(character, "release safehouse", self.safehouse, nil)
        end
    end
end

-- OnReleaseSafeHouseCommand rewrites original ISChat.onCommandEntered and
-- adds logs for player release safehouse action.
LogExtenderClient.OnReleaseSafeHouseCommand = function()
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

            LogExtenderClient.DumpSafehouse(character, "release safehouse", safehouse, nil)
        end

        onCommandEnteredOriginal(self)
    end
end

-- OnRemovePlayerFromSafehouse rewrites original ISSafehouseUI.onRemovePlayerFromSafehouse
-- and adds logs for remove player from safehouse action.
LogExtenderClient.OnRemovePlayerFromSafehouse = function()
    local onRemovePlayerFromSafehouseOriginal = ISSafehouseUI.onRemovePlayerFromSafehouse;

    ISSafehouseUI.onRemovePlayerFromSafehouse = function(self, button, player)
        if button.internal == "YES" then
            local character = getPlayer()
            LogExtenderClient.DumpSafehouse(character, "remove player from safehouse", button.parent.ui.safehouse, button.parent.ui.selectedPlayer)
        end

        onRemovePlayerFromSafehouseOriginal(self, button, player)
    end
end

-- OnJoinToSafehouse rewrites original ISSafehouseUI.onAnswerSafehouseInvite and
-- adds logs for players join to safehouse action.
LogExtenderClient.OnJoinToSafehouse = function()
    local onAnswerSafehouseInviteOriginal = ISSafehouseUI.onAnswerSafehouseInvite;

    ISSafehouseUI.onAnswerSafehouseInvite = function(self, button)
        if button.internal == "YES" then
            local character = getPlayer()
            LogExtenderClient.DumpSafehouse(character, "join to safehouse", button.parent.safehouse, nil)
        end

        onAnswerSafehouseInviteOriginal(self, button)
    end
end

-- OnCreatePlayer adds callback for player OnCreatePlayerData event.
LogExtenderClient.OnCreatePlayer = function(id)
    Events.OnTick.Add(LogExtenderClient.OnTick);
end

-- OnTick creates and removes ticker for emulating player connected event.
-- This is Black Magic.
LogExtenderClient.OnTick = function()
    local player = getPlayer()
    if player then
        LogExtenderClient.DumpPlayer(player, "connected");
        Events.OnTick.Remove(LogExtenderClient.OnTick);
    end
end

-- OnPerkLevel adds callback for player OnPerkLevel global event.
LogExtenderClient.OnPerkLevel = function(player, perk, level)
    if player and perk and level then
        if instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
            -- Hide events from the log when creating a character.
            if player:getHoursSurvived() <= 0 then return end

            LogExtenderClient.DumpPlayer(player, "levelup");
        end
    end
end

-- EveryHours adds callback for EveryHours global event.
LogExtenderClient.EveryHours = function()
    local player = getSpecificPlayer(0);
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        -- Hide events from the log when creating a character.
        if player:getHoursSurvived() <= 0 then return end

        LogExtenderClient.DumpPlayer(player, "tick");
    end
end

-- VehicleEnter adds callback for OnEnterVehicle event.
LogExtenderClient.VehicleEnter = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        LogExtenderClient.vehicle = player:getVehicle()
        LogExtenderClient.DumpVehicle(player, "enter", LogExtenderClient.vehicle, nil);
    end
end

-- VehicleExit adds callback for OnExitVehicle event.
LogExtenderClient.VehicleExit = function(player)
    if player and instanceof(player, 'IsoPlayer') and player:isLocalPlayer() then
        LogExtenderClient.DumpVehicle(player, "exit", LogExtenderClient.vehicle, nil);
        LogExtenderClient.vehicle = nil
    end
end

-- VehicleAttach adds callback for ISAttachTrailerToVehicle event.
LogExtenderClient.VehicleAttach = function()
    local originalPerform = ISAttachTrailerToVehicle.perform;

    ISAttachTrailerToVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            LogExtenderClient.vehicleAttachment = self.vehicleB
            LogExtenderClient.DumpVehicle(player, "attach", self.vehicleA, self.vehicleB);
        end;
    end;
end

-- VehicleDetach adds callback for ISDetachTrailerFromVehicle event.
LogExtenderClient.VehicleDetach = function()
    local originalPerform = ISDetachTrailerFromVehicle.perform;

    ISDetachTrailerFromVehicle.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player then
            LogExtenderClient.DumpVehicle(player, "detach", self.vehicle, LogExtenderClient.vehicleAttachment);
            LogExtenderClient.vehicleAttachment = nil;
        end;
    end;
end

-- OnAddItemsFromTable overrides original ISItemsListTable.onOptionMouseDown and
-- ISItemsListTable.onAddItem and adds logs for additem actions.
LogExtenderClient.OnAddItemsFromTable = function()
    local originalOnOptionMouseDown = ISItemsListTable.onOptionMouseDown;
    local originalOnAddItem = ISItemsListTable.onAddItem;
    local originalCreateChildren = ISItemsListTable.createChildren;

    ISItemsListTable.onOptionMouseDown = function(self, button, x, y)
        originalOnOptionMouseDown(self, button, x, y);

        if button.internal == "ADDITEM" then
            return
        end

        local character = getSpecificPlayer(self.viewer.playerSelect.selected - 1)
        if not character or character:isDead() then return end

        local item = button.parent.datas.items[button.parent.datas.selected].item;
        local count = 0;

        if button.internal == "ADDITEM1" then
            count = 1
        end

        if button.internal == "ADDITEM2" then
            count = 2
        end

        if button.internal == "ADDITEM5" then
            count = 5
        end

        LogExtenderClient.DumpAdminItem(getPlayer(), "added", item:getFullName(), count, character)
    end

    ISItemsListTable.onAddItem = function(self, button, item)
        originalOnAddItem(self, button, item)

        local character = getSpecificPlayer(self.viewer.playerSelect.selected - 1)
        if not character or character:isDead() then return end

        local count = tonumber(button.parent.entry:getText())

        LogExtenderClient.DumpAdminItem(getPlayer(), "added", item:getFullName(), count, character)
    end

    local addItem = function(self, item)
        ISItemsListTable.addItem(self, item)

        local character = getSpecificPlayer(self.viewer.playerSelect.selected - 1)
        if not character or character:isDead() then return end

        LogExtenderClient.DumpAdminItem(getPlayer(), "added", item:getFullName(), 1, character)
    end

    ISItemsListTable.createChildren = function(self)
        originalCreateChildren(self)

        self.datas:setOnMouseDoubleClick(self, addItem)
    end
end

-- OnChangeItemsFromManageInventory overrides original ISPlayerStatsManageInvUI:onClick
-- for adding logs for remove and get items actions.
LogExtenderClient.OnChangeItemsFromManageInventory = function()
    local originalOnClick = ISPlayerStatsManageInvUI.onClick;

    ISPlayerStatsManageInvUI.onClick = function(self, button)
        originalOnClick(self, button);

        if self.selectedItem then
            if button.internal == "REMOVE" then
                LogExtenderClient.DumpAdminItem(getPlayer(), "removed", self.selectedItem.item.fullType, 1, self.player);
            end

            if button.internal == "GETITEM" then
                LogExtenderClient.DumpAdminItem(getPlayer(), "removed", self.selectedItem.item.fullType, 1, self.player);
                LogExtenderClient.DumpAdminItem(getPlayer(), "added", self.selectedItem.item.fullType, 1, getPlayer());
            end
        end
    end
end

-- OnGameStart adds callback for OnGameStart global event.
LogExtenderClient.OnGameStart = function()
    LogExtenderClient.player = getPlayer();

    if SandboxVars.LogExtender.PlayerLevelup then
        Events.LevelPerk.Add(LogExtenderClient.OnPerkLevel);
    end

    if SandboxVars.LogExtender.PlayerTick then
        Events.EveryHours.Add(LogExtenderClient.EveryHours);
    end

    if SandboxVars.LogExtender.VehicleEnter then
        Events.OnEnterVehicle.Add(LogExtenderClient.VehicleEnter);
    end

    if SandboxVars.LogExtender.VehicleExit then
        Events.OnExitVehicle.Add(LogExtenderClient.VehicleExit);
    end

    if SandboxVars.LogExtender.VehicleAttach then
        LogExtenderClient.VehicleAttach()
    end

    if SandboxVars.LogExtender.VehicleDetach then
        LogExtenderClient.VehicleDetach()
    end

    if SandboxVars.LogExtender.TimedActions then
        LogExtenderClient.TimedActionPerform();
    end

    if SandboxVars.LogExtender.TakeSafeHouse then
        LogExtenderClient.OnTakeSafeHouse()
    end

    if SandboxVars.LogExtender.ReleaseSafeHouse then
        LogExtenderClient.OnReleaseSafeHouse()
    end

    if SandboxVars.LogExtender.RemovePlayerFromSafehouse then
        LogExtenderClient.OnRemovePlayerFromSafehouse()
    end

    if SandboxVars.LogExtender.JoinToSafehouse then
        LogExtenderClient.OnJoinToSafehouse()
    end

    if SandboxVars.LogExtender.AdminManageItem then
        LogExtenderClient.OnAddItemsFromTable()
        LogExtenderClient.OnChangeItemsFromManageInventory()
    end
end

if SandboxVars.LogExtender.PlayerConnected then
    Events.OnCreatePlayer.Add(LogExtenderClient.OnCreatePlayer);
end

if SandboxVars.LogExtender.ReleaseSafeHouse then
    LogExtenderClient.OnReleaseSafeHouseCommand()
end

Events.OnGameStart.Add(LogExtenderClient.OnGameStart);
