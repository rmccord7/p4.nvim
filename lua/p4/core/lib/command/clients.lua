local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Clients_Options : table

--- @class P4_Command_Clients_Result : table
--- @field client_name string P4 client name.
--- @field root string client root.

--- @class P4_Command_Clients : P4_Command
--- @field opts P4_Command_Clients_Options Command options.
local P4_Command_Clients = {}

P4_Command_Clients.__index = P4_Command_Clients

setmetatable(P4_Command_Clients, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Clients_Result[] result Hold's the parsed result from the command output.
local function process_response(output)

  log.trace("P4_Command_Clients: process_response")

  --- @type P4_Command_Clients_Result[]
  local result = {}

  for _, line in ipairs(vim.split(output, "\n", {trimempty = true})) do

    local chunks = {}
    for substring in line:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    --- @type P4_Command_Clients_Result
    local file_info = {
      client_name = chunks[2],
      root = chunks[4],
    }

    table.insert(result, file_info)
  end

  return result
end

--- Creates the P4 command.
---
--- @param opts? P4_Command_Clients_Options P4 command options.
--- @return P4_Command_Clients P4_Command_Clients P4 command.
function P4_Command_Clients:new(opts)
  opts = opts or {}

  log.trace("P4_Command_Clients: new")

  local command = {
    "p4",
    "clients",
    "--me", -- Current user
    "-a", -- Get all clients (not just the ones on the connected p4 server)
  }

  --- @type P4_Command_Clients
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Clients)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Clients_Result[]|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_Clients:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Clients
