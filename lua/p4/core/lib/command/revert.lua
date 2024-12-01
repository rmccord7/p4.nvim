local log = require("p4.log")

--- @class P4_Command_Revert_Options : table
--- @field cl? integer Reverts only the specified files in the
---                    specified change list.

--- @class P4_Command_Revert_Result : table

--- @class P4_Command_Revert : P4_Command
--- @field opts P4_Command_Revert_Options Command options.
local P4_Command_Revert = {}

--- Creates the P4 command.
---
--- @param file_paths string|string[] One or more file paths.
--- @param opts? P4_Command_Revert_Options P4 command options.
--- @return P4_Command_Revert P4_Command_Revert P4 command.
function P4_Command_Revert:new(file_paths, opts)
  opts = opts or {}

  log.trace("P4_Command_Revert: new")

  P4_Command_Revert.__index = P4_Command_Revert

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Revert, {__index = P4_Command})

  local command = {
    "p4",
    "revert",
  }

  if opts.cl then

    local ext_cmd = {
      "-c", -- Revert files in specified CL
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  if type(file_paths) == "string" then
    table.insert(command, file_paths)
  else
    vim.list_extend(command, file_paths)
  end

  --- @type P4_Command_Revert
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Revert)

  return new
end

--- Parses the output of the P4 command.
function P4_Command_Revert:process_response()
  log.trace("P4_Command_Revert: process_response")
end

return P4_Command_Revert
