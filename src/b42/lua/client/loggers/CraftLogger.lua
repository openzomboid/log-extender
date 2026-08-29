--
-- Copyright (c) 2024 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

local CraftLogger = {}

function CraftLogger.IsEnabledOnServer()
    return SandboxVars.LogExtender.CraftLogs
end


-- TimedActionPerform overrides the original ISBaseTimedAction:perform function to gain access to player events.
function CraftLogger.TimedActionPerform()
    local originalPerform = ISBaseTimedAction.perform

    ISBaseTimedAction.perform = function(self)
        originalPerform(self)

        local character = self.character

        if character and self.Type then
            local location = logutils.GetLocation(character)

            if self.Type == "ISCraftAction" then
                local recipe = self.recipe
                local recipeName = recipe:getOriginalname()
                local result = recipe:getResult()
                local resultType = result:getFullType()
                local resultCount = result:getCount()
    
                local message = logutils.GetLogLinePrefix(character, "crafted") .. " " .. resultCount .. " " .. resultType .. " with recipe \"" .. recipeName .. "\" (" .. location .. ")"
                logutils.WriteLog(logutils.filemask.craft, message)
            elseif self.Type == "ISHandcraftAction" then
                local recipe = self.craftRecipe
                local recipeName = recipe:getName()

                local items = recipe:getOutputs()

                for i=0,items:size()-1 do
                    local result = items:get(i)
                    local resultType = result:getFullType()

                    local message = logutils.GetLogLinePrefix(character, "crafted") .. " 1 " .. resultType .. " with recipe \"" .. recipeName .. "\" (" .. location .. ")"
                    logutils.WriteLog(logutils.filemask.craft, message)
                end
            end
        end
    end
end

-- OnGameStart adds callback for OnGameStart global event.
CraftLogger.OnGameStart = function()
    if CraftLogger.IsEnabledOnServer() then
        CraftLogger.TimedActionPerform()
    end
end

Events.OnGameStart.Add(CraftLogger.OnGameStart)
