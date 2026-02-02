---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Command_Submit_Options : table
--- @field cl string Only files in the specified changelist.

--- @class P4_Command_Submit_Result : boolean

--- @class P4_Command_Submit : P4_Command
--- @field opts P4_Command_Submit_Options Command options.
local P4_Command_Submit = {}

P4_Command_Submit.__index = P4_Command_Submit

setmetatable(P4_Command_Submit, {__index = cmd_lib})

--- Parses the output of the P4 command.
function P4_Command_Submit:_process_response()
  log.trace("P4_Command_Submit: process_response")
end

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] File spec.
--- @param opts? P4_Command_Submit_Options P4 command options.
--- @return P4_Command_Submit P4_Command_Submit P4 command.
function P4_Command_Submit:new(file_spec_list, opts)
  opts = opts or {}

  local command = {
    "submit",
  }

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  table.insert(command, file_spec_list)

  --- @type P4_Command_Submit
  local new = cmd_lib:new(command)

  setmetatable(new, P4_Command_Submit)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Submit_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Submit:run()

  local success, _ = pcall(cmd_lib.run(self).wait)

  return success
end

return P4_Command_Submit
