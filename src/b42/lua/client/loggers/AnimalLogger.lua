--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

-- Fallback logger initialization if ConsoleLogger is not present in the global environment.
local logger = ConsoleLogger and ConsoleLogger.new() or {
    Debug = function(msg) print("ConsoleLogger DEBUG: " .. msg) end
}

local AnimalLogger = {
    actions = {
        { class = "ISKillAnimal",              name = "killed" },
        { class = "ISKillAnimalInInventory",   name = "killed in inventory",  stop = true},
        { class = "ISPickupAnimal",            name = "picked up",            stop = true }, -- TODO: Add drop action (is's not specific animals action)
        { class = "ISButcherAnimal",           name = "butchered",            start = true},
        { class = "ISPutAnimalOnHook",         name = "putted to hook" },
        { class = "ISRemoveAnimalFromHook",    name = "released from hook" },
        { class = "ISAddAnimalInTrailer",      name = "putted to trailer",    stop = true },
        { class = "ISRemoveAnimalFromTrailer", name = "released from trailer" },
        { class = "ISAttachAnimalToPlayer",    name = "attached",             remove = "detached" },
        { class = "ISPutAnimalInHutch",        name = "putted to hutch" },
        { class = "ISHutchGrabAnimal",         name = "released from hutch" }
    },
    pendingHits = {}
}

function AnimalLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.AnimalLogs
end

function AnimalLogger.GetAnimalID(animal)
    if animal == nil or not animal.getAnimalID then
        return 0
    end

    return animal:getAnimalID() or 0
end

function AnimalLogger.GetAnimalType(animal)
    if animal == nil then
        return "unknown animal"
    end

    local animalPrefix = "unknown"
    local animalType = "animal"

    if animal.getData and animal:getData().getBreed and animal:getData():getBreed().getName then
        local raw = animal:getData():getBreed():getName()
        if raw and raw ~= "" and raw ~= "nil" then
            animalPrefix = raw
        end
    end

    if animal.getAnimalType then
        local raw = animal:getAnimalType()
        if raw and raw ~= "" and raw ~= "nil" then
            animalType = raw
        end
    end

    return animalPrefix .. " " .. animalType
end

function AnimalLogger.GetAnimalFromTimedAction(self)
    if self.animalItem and self.animalItem:getAnimal() then
        return self.animalItem:getAnimal()
    end

    return self.animal or self.target or self.item
end

function AnimalLogger.WriteAnimalAction(action, animal)
    if not AnimalLogger.IsEnabledOnServer() then
        return
    end

    local id = AnimalLogger.GetAnimalID(animal)
    local name = AnimalLogger.GetAnimalType(animal)

    local message = '"' .. name .. '" with id ' .. tostring(id)

    logutils.WriteLog(logutils.filemask.animal, action, message)
end

function AnimalLogger.OnGameStart()
    if not AnimalLogger.IsEnabledOnServer() then
        return
    end

    for _, action in ipairs(AnimalLogger.actions) do
        local actionClass = _G[action.class]

        if actionClass then
            if actionClass.perform then
                logger.Debug("AnimalLogger: animal action " .. action.class .. " 'perform' wrapper registered")

                local _perform = actionClass.perform
                actionClass.perform = function(self)
                    logger.Debug("AnimalLogger: called 'perform' wrapper in class " .. action.class)

                    local animal = AnimalLogger.GetAnimalFromTimedAction(self)

                    local actionName = action.name
                    if action.remove and self.remove then
                        actionName = action.remove
                    end

                    _perform(self)
                    AnimalLogger.WriteAnimalAction(actionName, animal)
                end
            end

            if action.start and actionClass.start then
                logger.Debug("AnimalLogger: animal action " .. action.class .. " 'start' wrapper registered")

                local _start = actionClass.start
                actionClass.start = function(self)
                    logger.Debug("AnimalLogger: called 'start' wrapper in class " .. action.class)

                    local animal = AnimalLogger.GetAnimalFromTimedAction(self) or self.body

                    _start(self)

                    AnimalLogger.WriteAnimalAction(action.name, animal)
                end
            end

            if action.stop and actionClass.stop then
                logger.Debug("AnimalLogger: animal action " .. action.class .. " 'stop' wrapper registered")

                local _stop = actionClass.stop
                actionClass.stop = function(self)
                    logger.Debug("AnimalLogger: called 'stop' wrapper in class " .. action.class)

                    local animal = AnimalLogger.GetAnimalFromTimedAction(self)

                    local _, delta = pcall(function() return self.action:getJobDelta() end)
                    if delta >= 0.9 then
                        AnimalLogger.WriteAnimalAction(action.name, animal)
                    end

                    return _stop(self)
                end
            end
        else
            logger.Debug("AnimalLogger: animal action " .. action.class .. " not found")
        end
    end

    Events.OnWeaponHitCharacter.Add(AnimalLogger.OnWeaponHitCharacter)
    Events.OnTick.Add(AnimalLogger.ProcessPendingHits)
    Events.OnCharacterDeath.Add(AnimalLogger.OnCharacterDeath)
end

function AnimalLogger.OnWeaponHitCharacter(wielder, target, weapon, damage)
    if not AnimalLogger.IsEnabledOnServer() then return end
    if not wielder or not instanceof(wielder, "IsoPlayer") or not wielder:isLocalPlayer() then return end
    if not target or not instanceof(target, "IsoAnimal") then return end

    local dmgVal = damage or 0
    if dmgVal <= 0 then return end

    local animalId = AnimalLogger.GetAnimalID(target)
    local dmgRounded = math.floor(dmgVal * 10) / 10
    local health = target:getHealth() or 0

    for _, entry in ipairs(AnimalLogger.pendingHits) do
        if entry.id == animalId and entry.initialHp == health then
            logger.Debug("AnimalLogger: OnWeaponHitCharacter: same event")
            return
        end
    end

    table.insert(AnimalLogger.pendingHits, {
        target      = target,
        id          = animalId,
        name        = AnimalLogger.GetAnimalType(target),
        isRanged    = weapon and weapon.isRanged and weapon:isRanged(),
        weaponName  = (weapon and weapon.getFullType) and ('"' .. weapon:getFullType() .. '"') or '"Bare hands"',
        dmg         = dmgRounded,
        initialHp   = target:getHealth() or 0,
        ticksWaited = 0
    })
end

function AnimalLogger.ProcessPendingHits()
    if #AnimalLogger.pendingHits == 0 then return end

    for i = #AnimalLogger.pendingHits, 1, -1 do
        local entry = AnimalLogger.pendingHits[i]
        entry.ticksWaited = entry.ticksWaited + 1

        local target = entry.target
        local currentRawHp = target:getHealth() or 0
        local isGoneOrDead = target:isDead() or currentRawHp <= 0 or (target:getSquare() == nil)
        local hpChanged = math.abs(currentRawHp - entry.initialHp) > 0.0001

        if isGoneOrDead or hpChanged or entry.ticksWaited >= 30 then
            local action = entry.isRanged and "attacked (ranged)" or "attacked (melee)"

            local curHp = isGoneOrDead and 0 or math.floor(currentRawHp * 100)
            local maxHp = math.floor((target.getMaxHealth and target:getMaxHealth() or 100) * 10) / 10

            local hpStr = string.format("hp=%.1f/%.1f", curHp, maxHp)
            if isGoneOrDead then
                hpStr = hpStr .. " (killed)"
            end

            logger.Debug("AnimalLogger: ProcessPendingHits: write log on " .. tostring(entry.ticksWaited) .. " tick")
            local message = '"' .. entry.name .. '" with id ' .. tostring(entry.id) .. ' using ' .. entry.weaponName .. ' damage=' .. tostring(entry.dmg) .. ' ' .. hpStr
            logutils.WriteLog(logutils.filemask.animal, action, message)

            entry = nil
            table.remove(AnimalLogger.pendingHits, i)
        end
    end
end

function AnimalLogger.OnCharacterDeath(character)
    if not AnimalLogger.IsEnabledOnServer() then return end
    if not character or not instanceof(character, "IsoAnimal") then return end

    local killer = character.getAttackedBy and character:getAttackedBy() or nil

    -- If the attacker is known and is NOT the local player (e.g., another player shot the animal), return.
    if killer and instanceof(killer, "IsoPlayer") and not killer:isLocalPlayer() then
        logger.Debug("AnimalLogger: OnCharacterDeath: Killer \"" .. killer:getUsername() .. "\" is not interrest")
        return
    end

    if not killer or not instanceof(killer, "IsoPlayer") then
        logger.Debug("AnimalLogger: OnCharacterDeath: get killer from getPlayer()")
        killer = getPlayer()
    end

    if not killer or not instanceof(killer, "IsoPlayer") or not killer:isLocalPlayer() then return end

    local vehicle = killer:getVehicle()
    if not vehicle then return end
    if vehicle:getDriver() ~= killer then return end

    -- Distance check for long vehicles (trucks/trailers): measure distance from both the player and the vehicle center (max 5-6 tiles)
    local distFromPlayer = killer:DistTo(character)
    local distFromVehicle = vehicle:DistTo(character)
    if distFromPlayer > 6.5 and distFromVehicle > 6.0 then
        logger.Debug("AnimalLogger: OnCharacterDeath: killer's distance check failed")
        return
    end

    local id = AnimalLogger.GetAnimalID(character)
    local name = AnimalLogger.GetAnimalType(character)
    local vehicleName = vehicle:getScriptName() or "Unknown Vehicle"

    local message = string.format('"%s" with id %s (vehicle "%s")', name, tostring(id), vehicleName)
    logutils.WriteLog(logutils.filemask.animal, "killed by vehicle", message)
end

Events.OnGameStart.Add(AnimalLogger.OnGameStart)
