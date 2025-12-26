local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Print_Options : table

--- @class P4_Command_Print_Result : boolean

--- @class P4_Command_Print : P4_Command
--- @field opts P4_Command_Print_Options Command options.
local P4_Command_Print = {}

P4_Command_Print.__index = P4_Command_Print

setmetatable(P4_Command_Print, {__index = P4_Command})

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Print_Options P4 command options.
--- @return P4_Command_Print P4_Command_Print P4 command.
function P4_Command_Print:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Print: new")

  local command = {
    "p4",
    "print",
    "-q", --Suppress the one line header added by perforce.
    "-o",
  }

  vim.list_extend(command, file_spec_list)

  --- @type P4_Command_Print
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Print)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Print_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Print:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("File(s) opened for edit")
  end

  return success
end

return P4_Command_Print
