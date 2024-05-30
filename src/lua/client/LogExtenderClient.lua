--
-- Copyright (c) 2022 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--
-- LogExtenderClient adds more logs to the Logs directory the Project Zomboid game.
--

LogExtenderClient = {
    version = logutils.version,
    pzversion = getCore():getVersionNumber(),
    
    -- Placeholders for Project Zomboid log file names.
    -- Project Zomboid generates files like this 24-08-19_18-11_chat.txt
    -- at first action and use file until next server restart.
    filemask = {
        chat = "chat",
        user = "user",
        cmd = "cmd",
        item = "item",
        map = "map",
        pvp = "pvp",
        vehicle = "vehicle",
        player = "player",
        admin = "admin",
        safehouse = "safehouse",
        craft = "craft",
        map_alternative = "map_alternative",
        brushtool = "brushtool",
    }
}

-- writeLog sends command to server for writting log line to file.
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.writeLog(filemask, message)
    sendClientCommand("LogExtender", "write", { mask = filemask, message = message });
end

-- getLogLinePrefix generates prefix for each log lines.
-- for ease of use, we assume that the player’s existence has been verified previously.
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getLogLinePrefix(player, action)
    -- TODO: Add ownerID.
    return getCurrentUserSteamID() .. " \"" .. player:getUsername() .. "\" " .. action
end

-- getLocation returns players or vehicle location in "x,x,z" format.
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getLocation(obj)
    return math.floor(obj:getX()) .. "," .. math.floor(obj:getY()) .. "," .. math.floor(obj:getZ());
end

-- getPlayerSafehouses iterates in server safehouse list and returns
-- area coordinates of player's houses.
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getPlayerSafehouses(player)
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
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getPlayerPerks(player)
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
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getPlayerTraits(player)
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
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getPlayerStats(player)
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
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getPlayerHealth(player)
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
-- Deprecated: Moved to logutils.
-- TODO: Will be removed from LogExtenderClient on next releases.
function LogExtenderClient.getVehicleInfo(vehicle)
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
    info.Center = logutils.GetLocation(vehicle:getCurrentSquare());

    return info;
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

    logutils.WriteLog(logutils.filemask.admin, message);
end

-- TimedActionPerform overrides the original ISBaseTimedAction: perform function to gain
-- access to player events.
LogExtenderClient.TimedActionPerform = function()
    local originalPerform = ISBaseTimedAction.perform;

    ISBaseTimedAction.perform = function(self)
        originalPerform(self);

        local player = self.character;

        if player and self.Type then
            local location = logutils.GetLocation(player);

            if self.Type == "ISTakeGenerator" then
                local message = logutils.GetLogLinePrefix(player, "taken IsoGenerator") .. " (appliances_misc_01_0) at " .. location;
                logutils.WriteLog(logutils.filemask.map, message);
                if SandboxVars.LogExtender.AlternativeMap then
                    logutils.WriteLog(logutils.filemask.map_alternative, message);
                end
            elseif self.Type == "ISToggleStoveAction" then
                local message = logutils.GetLogLinePrefix(player, "stove.toggle") .. " @ " .. location;
                logutils.WriteLog(logutils.filemask.cmd, message);
            elseif self.Type == "ISPlaceCampfireAction" then
                local message = logutils.GetLogLinePrefix(player, "added Campfire") .. " (camping_01_6) at " .. location;
                logutils.WriteLog(logutils.filemask.map, message);
                if SandboxVars.LogExtender.AlternativeMap then
                    logutils.WriteLog(logutils.filemask.map_alternative, message);
                end
            elseif self.Type == "ISRemoveCampfireAction" then
                local message = logutils.GetLogLinePrefix(player, "taken Campfire") .. " (camping_01_6) at " .. location;
                logutils.WriteLog(logutils.filemask.map, message);
                if SandboxVars.LogExtender.AlternativeMap then
                    logutils.WriteLog(logutils.filemask.map_alternative, message);
                end
            elseif (self.Type == "ISLightFromKindle" or self.Type == "ISLightFromLiterature" or self.Type == "ISLightFromPetrol") then
                local message = logutils.GetLogLinePrefix(player, "campfire.light") .. " @ " .. location;
                logutils.WriteLog(logutils.filemask.cmd, message);
            elseif self.Type == "ISPutOutCampfireAction" then
                local message = logutils.GetLogLinePrefix(player, "campfire.extinguish") .. " @ " .. location;
                logutils.WriteLog(logutils.filemask.cmd, message);
            elseif self.Type == "ISRemoveTrapAction" then
                local message = logutils.GetLogLinePrefix(player, "taken Trap") .. " (" .. self.trap.openSprite .. ") at " .. location;
                logutils.WriteLog(logutils.filemask.map, message);
                if SandboxVars.LogExtender.AlternativeMap then
                    logutils.WriteLog(logutils.filemask.map_alternative, message);
                end
            elseif self.Type == "ISCraftAction" then
                local recipe = self.recipe
                local recipeName = recipe:getOriginalname()
                local result = recipe:getResult()
                local resultType = result:getFullType()
                local resultCount = result:getCount()

                local message = logutils.GetLogLinePrefix(player, "crafted") .. " " .. resultCount .. " " .. resultType .. " with recipe \"" .. recipeName .. "\" (" .. location .. ")";
                logutils.WriteLog(logutils.filemask.craft, message);
            end;

            if SandboxVars.LogExtender.AlternativeMap then
                -- Action=removed - Destroyed with sledgehammer.
                if self.Type == "ISDestroyStuffAction" then
                    local obj = self.item;
                    local objLocation = ""
                    if obj.GetX ~= nil then
                        objLocation = logutils.GetLocation(obj);
                    else
                        -- Workaround for destroying IsoRadio and IsoTelevision from Brush Tool.
                        -- That objects doesn't have x,y,z position. We only can get IsoGridSquare
                        -- from object stack and then we can get position.
                        local coroutine = getCurrentCoroutine();
                        local count = getCoroutineTop(coroutine);
                        for i = count - 1, 0, -1 do
                            local o = getCoroutineObjStack(coroutine, i);
                            if o ~= nil and instanceof(o, 'IsoGridSquare') then
                                objLocation = logutils.GetLocation(o);
                                break;
                            end
                        end

                        if objLocation == nil or objLocation == "" then
                            objLocation = location
                        end
                    end
                    local sprite = obj:getSprite();
                    local spriteName = sprite:getName() or "undefined"
                    local objName = obj:getName() or obj:getObjectName();
                    if objName == "" then
                        objName = instanceof(self.item, 'IsoThumpable') and "IsoThumpable" or "undefined"
                    end

                    local message = logutils.GetLogLinePrefix(player, "removed " .. objName) .. " (" .. spriteName .. ") at " .. objLocation .. " (" .. location .. ")";
                    logutils.WriteLog(logutils.filemask.map_alternative, message);
                elseif self.Type == "ISMoveablesAction" then
                    -- Action=disassembled - Disassembled with tools.
                    if self.mode and self.mode=="scrap" and self.moveProps and self.moveProps.object then
                        local obj = self.moveProps.object;
                        local objLocation = logutils.GetLocation(self.square);
                        local sprite = obj:getSprite();
                        local spriteName = sprite:getName() or "undefined"
                        local objName = obj:getName() or obj:getObjectName();
                        if objName == "" then
                            objName = instanceof(self.item, 'IsoThumpable') and "IsoThumpable" or "undefined"
                        end

                        local message = logutils.GetLogLinePrefix(player, "disassembled " .. objName) .. " (" .. spriteName .. ") at " .. objLocation .. " (" .. location .. ")";
                        logutils.WriteLog(logutils.filemask.map_alternative, message);
                    end

                    -- Action=pickedup - Picked up to inventory.
                    if self.mode and self.mode=="pickup" and self.moveProps then
                        local objLocation = logutils.GetLocation(self.square);
                        local sprite = self.moveProps.sprite;
                        local spriteName = sprite:getName() or "undefined"
                        local objName = self.moveProps.isoType;

                        local message = logutils.GetLogLinePrefix(player, "pickedup " .. objName) .. " (" .. spriteName .. ") at " .. objLocation .. " (" .. location .. ")";
                        logutils.WriteLog(logutils.filemask.map_alternative, message);
                    end
                end
            end
        end;
    end;
end

-- WeaponHitThumpable adds objects hit record to map_alternative log file.
-- [12-12-22 07:08:28.916] 76561190000000000 "outdead" destroyed IsoObject (location_restaurant_spiffos_02_25) with Base.Axe at 11633,8265,0 (11633,8265,0).
-- TODO: Make me work.
LogExtenderClient.WeaponHitThumpable = function(character, weapon, object)
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

-- WeaponHitCharacter adds player hit record to pvp log file.
-- [06-07-22 04:12:00.737] user Player1 (6823,5488,0) hit user Player2 (6822,5488,0) with Base.HuntingKnife damage 1.137.
LogExtenderClient.WeaponHitCharacter = function(attacker, target, weapon, damage)
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

-- OnGiveIngredients overrides ISCraftingUI:debugGiveIngredients
-- for adding logs for additem actions.
LogExtenderClient.OnGiveIngredients = function()
    local originalDebugGiveIngredients = ISCraftingUI.debugGiveIngredients;

    ISCraftingUI.debugGiveIngredients = function(self)
        originalDebugGiveIngredients(self);

        local recipeListBox = self:getRecipeListBox()
        local selectedItem = recipeListBox.items[recipeListBox.selected].item
        if selectedItem.evolved then return end
        local recipe = selectedItem.recipe
        local items = {}
        local options = {}
        options.AvailableItemsAll = RecipeManager.getAvailableItemsAll(recipe, self.character, self:getContainers(), nil, nil)
        options.MaxItemsPerSource = 10
        options.NoDuplicateKeep = true
        RecipeUtils.CreateSourceItems(recipe, options, items)

        local mapItems = {}

        for _,item in ipairs(items) do
            local code = item:getFullType()
            local count = mapItems[code] or 0
            mapItems[code] = count + 1
        end

        for code, count in pairs(mapItems) do
            LogExtenderClient.DumpAdminItem(self.character, "added", code, count, self.character);
        end
    end
end

-- OnTeleport adds logs for teleport actions.
LogExtenderClient.OnTeleport = function()
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
LogExtenderClient.OnGameStart = function()
    if SandboxVars.LogExtender.TimedActions then
        LogExtenderClient.TimedActionPerform()
    end

    if SandboxVars.LogExtender.HitPVP then
        Events.OnWeaponHitCharacter.Add(LogExtenderClient.WeaponHitCharacter)
    end

    if SandboxVars.LogExtender.AdminManageItem then
        LogExtenderClient.OnAddItemsFromTable()
        LogExtenderClient.OnChangeItemsFromManageInventory()
    end

    if SandboxVars.LogExtender.AdminTeleport then
        LogExtenderClient.OnTeleport()
    end
end

Events.OnWeaponHitThumpable.Add(LogExtenderClient.WeaponHitThumpable)

if SandboxVars.LogExtender.AdminManageItem then
    LogExtenderClient.OnGiveIngredients()
end

Events.OnGameStart.Add(LogExtenderClient.OnGameStart);
