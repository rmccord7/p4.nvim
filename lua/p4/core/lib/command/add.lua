local log = require("p4.log")

--- @class P4_Command_Add_Options : table

--- @class P4_Command_Add_Result : table

--- @class P4_Command_Add : P4_Command
--- @field opts P4_Command_Add_Options Command options.
local P4_Command_Add = {}

--- Creates the P4 command.
---
--- @param file_path_list P4_Host_File_Spec[] One or more file paths.
--- @param opts? P4_Command_Add_Options P4 command options.
--- @return P4_Command_Add P4_Command_Add P4 command.
function P4_Command_Add:new(file_path_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Add: new")

  P4_Command_Add.__index = P4_Command_Add

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Add, {__index = P4_Command})

  local command = {
    "p4",
    "add",
  }

  vim.list_extend(command, file_path_list)

  --- @type P4_Command_Add
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Add)

  return new
end

--- Parses the output of the P4 command.
---
--- @param output string Command output.
function P4_Command_Add:process_response(output)
  log.trace("P4_Command_Add: process_response")

  return output
end

return P4_Command_Add
