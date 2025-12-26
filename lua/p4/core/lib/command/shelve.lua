local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Shelve_Options : table
--- @field cl? integer Shelves only the specified files in the
---                    specified change list.

--- @class P4_Command_Shelve_Result : boolean

--- @class P4_Command_Shelve : P4_Command
--- @field opts P4_Command_Shelve_Options Command options.
local P4_Command_Shelve = {}

P4_Command_Shelve.__index = P4_Command_Shelve

setmetatable(P4_Command_Shelve, {__index = P4_Command})

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Shelve_Options P4 command options.
--- @return P4_Command_Shelve P4_Command_Shelve P4 command.
function P4_Command_Shelve:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Shelve: new")

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

  vim.list_extend(command, file_spec_list)

  --- @type P4_Command_Shelve
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Shelve)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Shelve_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Shelve:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("File(s) shelved")
  end

  return success
end

return P4_Command_Shelve
