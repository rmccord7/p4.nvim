local log = require("p4.log")

--- @class P4_Command_Reopen_Options : table
--- @field cl string Only files in the specified changelist.

--- @class P4_Command_Reopen_Result : table

--- @class P4_Command_Reopen : P4_Command
--- @field opts P4_Command_Reopen_Options Command options.
local P4_Command_Reopen = {}

--- Creates the P4 command.
---
--- @param file_spec_list P4_File_Spec[] File spec.
--- @param opts? P4_Command_Reopen_Options P4 command options.
--- @return P4_Command_Reopen P4_Command_Reopen P4 command.
function P4_Command_Reopen:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Reopen: new")

  P4_Command_Reopen.__index = P4_Command_Reopen

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Reopen, {__index = P4_Command})

  local command = {
    "p4",
    "reopen",
  }

  assert(opts.cl, "CL must be specified for P4 reopen command.")

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  table.insert(command, file_spec_list)

  --- @type P4_Command_Reopen
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Reopen)

  return new
end

--- Parses the output of the P4 command.
function P4_Command_Reopen:process_response()
  log.trace("P4_Command_Reopen: process_response")
end

return P4_Command_Reopen
