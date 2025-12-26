local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Revert_Options : table
--- @field cl? integer Reverts only the specified files in the
---                    specified change list.

--- @class P4_Command_Revert_Result : boolean

--- @class P4_Command_Revert : P4_Command
--- @field opts P4_Command_Revert_Options Command options.
local P4_Command_Revert = {}

P4_Command_Revert.__index = P4_Command_Revert

setmetatable(P4_Command_Revert, {__index = P4_Command})


--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Revert_Options P4 command options.
--- @return P4_Command_Revert P4_Command_Revert P4 command.
function P4_Command_Revert:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Revert: new")

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

  vim.list_extend(command, file_spec_list)

  --- @type P4_Command_Revert
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Revert)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Revert_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Revert:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("File(s) reverted")
  end

  return success
end

return P4_Command_Revert
