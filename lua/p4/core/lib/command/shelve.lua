local log = require("p4.log")

--- @class P4_Command_Shelve_Options : table
--- @field cl? integer Shelves only the specified files in the
---                    specified change list.

--- @class P4_Command_Shelve_Result : table

--- @class P4_Command_Shelve : P4_Command
--- @field opts P4_Command_Shelve_Options Command options.
local P4_Command_Shelve = {}

--- Creates the P4 command.
---
--- @param file_paths string|string[] One or more file paths.
--- @param opts? P4_Command_Shelve_Options P4 command options.
--- @return P4_Command_Shelve P4_Command_Shelve P4 command.
function P4_Command_Shelve:new(file_paths, opts)
  opts = opts or {}

  log.trace("P4_Command_Shelve: new")

  P4_Command_Shelve.__index = P4_Command_Shelve

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Shelve, {__index = P4_Command})

  local command = {
    "p4",
    "shelve",
  }

  if opts.cl then

    local ext_cmd = {
      "-c", -- Shelve files in specified CL
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  if type(file_paths) == "string" then
    table.insert(command, file_paths)
  else
    vim.list_extend(command, file_paths)
  end

  --- @type P4_Command_Shelve
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Shelve)

  return new
end

--- Parses the output of the P4 command.
function P4_Command_Shelve:process_response()
  log.trace("P4_Command_Shelve: process_response")
end

return P4_Command_Shelve
