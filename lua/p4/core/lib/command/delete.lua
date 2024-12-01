local log = require("p4.log")

--- @class P4_Command_Delete_Options : table
--- @field cl? string Limits specified files to the specified CL

--- @class P4_Command_Delete_Result : table

--- @class P4_Command_Delete : P4_Command
--- @field opts P4_Command_Delete_Options Command options.
local P4_Command_Delete = {}

--- Creates the P4 command.
---
--- @param file_paths string|string[] One or more file paths.
--- @param opts? P4_Command_Delete_Options P4 command options.
--- @return P4_Command_Delete P4_Command_Delete P4 command.
function P4_Command_Delete:new(file_paths, opts)
  opts = opts or {}

  log.trace("P4_Command_Delete: new")

  P4_Command_Delete.__index = P4_Command_Delete

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Delete, {__index = P4_Command})

  local command = {
    "p4",
    "delete",
  }

  -- Specify change list
  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  if type(file_paths) == "string" then
    table.insert(command, file_paths)
  else
    vim.list_extend(command, file_paths)
  end

  --- @type P4_Command_Delete
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Delete)

  return new
end

--- Parses the output of the P4 command.
function P4_Command_Delete:process_response()
  log.trace("P4_Command_Delete: process_response")
end

return P4_Command_Delete
