local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Delete_Options : table
--- @field cl? string Limits specified files to the specified CL

--- @class P4_Command_Delete_Result : boolean

--- @class P4_Command_Delete : P4_Command
--- @field opts P4_Command_Delete_Options Command options.
local P4_Command_Delete = {}

P4_Command_Delete.__index = P4_Command_Delete

setmetatable(P4_Command_Delete, {__index = P4_Command})

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Delete_Options P4 command options.
--- @return P4_Command_Delete P4_Command_Delete P4 command.
function P4_Command_Delete:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Delete: new")

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

  vim.list_extend(command, file_spec_list)

  --- @type P4_Command_Delete
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Delete)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Delete_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Delete:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("File(s) deleted")
  end

  return success
end

return P4_Command_Delete
