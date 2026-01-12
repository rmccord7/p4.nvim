local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Clients_Result_Success
--- @field Access string Action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field Backup Local_File_Path Local file path.
--- @field Description Depot_File_Path Depot file path.
--- @field Host string Revision number.
--- @field LineEnd string Revision number.
--- @field Options string Revision number.
--- @field Owner string Revision number.
--- @field Root string Revision number.
--- @field SubmitOptions string Revision number.
--- @field Type string Revision number.
--- @field Udpate string Revision number.
--- @field Client string Revision number.

--- @class P4_Command_Clients_Result_Error
--- @field error P4_Command_Result_Error Hold's the error information.

--- @class P4_Command_Clients_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Clients_Result_Success | P4_Command_Clients_Result_Error Hold's information about the result.

--- @class P4_Command_Clients_Result : table
--- @field client_name string P4 client name.
--- @field root string client root.

--- @class P4_Command_Clients : P4_Command
local P4_Command_Clients = {}

P4_Command_Clients.__index = P4_Command_Clients

setmetatable(P4_Command_Clients, {__index = P4_Command})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Clients:_check_instance()
  assert(P4_Command.is_instance(self) == true, "Not a class instance")
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Files_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Clients:_process_response(sc)
  log.trace("P4_Command_Clients: process_response")

  -- Call base to process the response since we should have one JSON table per file spec.
  local success, results = P4_Command._process_response(self, sc)

  --- @cast results P4_Command_Clients_Result[]

  return success, results
end

--- Creates the P4 command.
---
--- @return P4_Command_Clients P4_Command_Clients P4 command.
---
--- @nodiscard
function P4_Command_Clients:new()
  log.trace("P4_Command_Clients: new")

  local command = {
    "clients",
    "--me", -- Current user
    "-a", -- Get all clients (not just the ones on the connected p4 server)
  }

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  --- @type P4_Command_Clients
  local new = P4_Command:new(info)

  setmetatable(new, P4_Command_Clients)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Clients_Result[]? Result Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Clients:run()
  self:_check_instance()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    if sc then
      success, results = P4_Command_Clients:_process_response(sc)
    else
      success = false
    end
  end

  return success, result
end

return P4_Command_Clients
