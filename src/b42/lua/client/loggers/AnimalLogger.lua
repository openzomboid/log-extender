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
        { class = "ISKillAnimalInInventory",   name = "killed in inventory",  alt = true},
        { class = "ISPickupAnimal",            name = "picked up",            alt = true }, -- TODO: no drop action
        { class = "ISButcherAnimal",           name = "butchered" },
        { class = "ISPutAnimalOnHook",         name = "putted to hook" },
        { class = "ISRemoveAnimalFromHook",    name = "released from hook" },
        { class = "ISAddAnimalInTrailer",      name = "putted to trailer",    alt = true },
        { class = "ISRemoveAnimalFromTrailer", name = "released from trailer" },
        { class = "ISAttachAnimalToPlayer",    name = "attached" }, -- TODO: detached writes attached, FIXME
        { class = "ISPutAnimalInHutch",        name = "putted to hutch" },
        { class = "ISHutchGrabAnimal",         name = "released from hutch" }
    }
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
        return "Unknown Animal"
    end

    local animalPrefix = "Unknown"
    local animalType = "Animal"

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

                    _perform(self)
                    AnimalLogger.WriteAnimalAction(action.name, animal)
                end
            end

            if action.alt and actionClass.stop then
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
end

Events.OnGameStart.Add(AnimalLogger.OnGameStart)
