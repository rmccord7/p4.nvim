local log = require("p4.log")

--- @class P4_Command_Edit_Options : table

--- @class P4_Command_Edit_Result : table

--- @class P4_Command_Edit : P4_Command
--- @field opts P4_Command_Edit_Options Command options.
local P4_Command_Edit = {}

--- Creates the P4 command.
---
--- @param file_paths string|string[] One or more file paths.
--- @param opts? P4_Command_Edit_Options P4 command options.
--- @return P4_Command_Edit P4_Command_Edit P4 command.
function P4_Command_Edit:new(file_paths, opts)
  opts = opts or {}

  log.trace("P4_Command_Edit: new")

  P4_Command_Edit.__index = P4_Command_Edit

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Edit, {__index = P4_Command})

  local command = {
    "p4",
    "edit",
  }

  if type(file_paths) == "string" then
    table.insert(command, file_paths)
  else
    vim.list_extend(command, file_paths)
  end

  --- @type P4_Command_Edit
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Edit)

  return new
end

--- Parses the output of the P4 command.
function P4_Command_Edit:process_response()
  log.trace("P4_Command_Edit: process_response")
end

return P4_Command_Edit
