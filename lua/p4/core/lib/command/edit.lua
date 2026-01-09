local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Edit_Options : table

--- @class P4_Command_Edit_Result : boolean

--- @class P4_Command_Edit : P4_Command
--- @field opts P4_Command_Edit_Options Command options.
local P4_Command_Edit = {}

P4_Command_Edit.__index = P4_Command_Edit

setmetatable(P4_Command_Edit, {__index = P4_Command})

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Edit_Options P4 command options.
--- @return P4_Command_Edit P4_Command_Edit P4 command.
function P4_Command_Edit:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Edit: new")

  local command = {
    "p4",
    "-Mj",
    "-ztag",
    "edit",
  }

  vim.list_extend(command, file_spec_list)

  --- @type P4_Command_Edit
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Edit)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Edit_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Edit:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("File(s) opened for edit")
  end

  return success
end

return P4_Command_Edit
