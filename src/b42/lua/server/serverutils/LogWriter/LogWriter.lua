--
-- Copyright (c) 2026 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

if isClient() then return end

-- LogWriter creates server side callback to write logs.
local LogWriter = {}

-- onClientCommand adds LogExtender write log command.
function LogWriter.onClientCommand(module, command, character, args)
    if module ~= "LogExtender" then
        return
    end

    if command == "write" then
        -- TODO: Add Username/SteamID validation. Check consistency of sender and target user in args
        writeLog(args.mask, args.message)
    end
end

Events.OnClientCommand.Add(LogWriter.onClientCommand)
