--
-- Copyright (c) 2022 outdead.
-- Use of this source code is governed by the Apache 2.0 license.
--

if isClient() then return end;

-- LogExtenderServer creates server side callback to write logs.
local LogExtenderServer = {}

-- onClientCommand adds LogExtender write log command.
LogExtenderServer.onClientCommand = function(module, command, playerObj, args)
    if module ~= "LogExtender" then
        return
    end

    if command == "write" then
        writeLog(args.mask, args.message);
    end
end

Events.OnClientCommand.Add(LogExtenderServer.onClientCommand);
