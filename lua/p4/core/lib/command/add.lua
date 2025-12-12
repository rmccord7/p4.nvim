local log = require("p4.log")
local notify = require("p4.notify")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Add_Options : table

--- @class P4_Command_Add_Result : boolean

--- @class P4_Command_Add : P4_Command
--- @field opts P4_Command_Add_Options Command options.
local P4_Command_Add = {}

P4_Command_Add.__index = P4_Command_Add

setmetatable(P4_Command_Add, {__index = P4_Command})

--- Creates the P4 command.
---
--- @param file_path_list P4_Host_File_Spec[] One or more file paths.
--- @param opts? P4_Command_Add_Options P4 command options.
--- @return P4_Command_Add P4_Command_Add P4 command.
function P4_Command_Add:new(file_path_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Add: new")

  local command = {
    "p4",
    "add",
  }

  vim.list_extend(command, file_path_list)

  --- @type P4_Command_Add
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Add)

  return new
end

--- Runs the P4 command.
---
--- @return P4_Command_Add_Result Result Indicates if the function was successful.
--- @async
function P4_Command_Add:run()

  local success, _ = pcall(P4_Command.run(self).wait)

  if success then
    notify("File(s) opened for add")
  end

  return success
end

return P4_Command_Add
