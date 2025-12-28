local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Where_Options : table

--- @class P4_Command_Where_Result : table
--- @field valid boolean Indicates if the file's stats are valid.
--- @field depot Depot_File_Path? Depot path to the file
--- @field client Client_File_Path? Client path to the file in local syntax
--- @field host Local_File_Path? Local path to the file
local P4_Command_Where_Result = {
  valid = false,
}

--- @class P4_Command_Where : P4_Command
--- @field opts P4_Command_Where_Options Command options.
local P4_Command_Where = {}

P4_Command_Where.__index = P4_Command_Where

setmetatable(P4_Command_Where, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_Where_Result[] result Hold's the parsed result from the command output.
function P4_Command_Where:_process_response(output)
  log.trace("P4_Command_Where: process_response")

  --- @type P4_Command_Where_Result[]
  local result_list = {}

  for _, file_path_list in ipairs(vim.split(output, "\n")) do

    --- @type P4_Command_Where_Result
    local result = {
      valid = false,
    }

    -- Handle files that are not in the depot or not opened in the client workspace.
    if not string.find(file_path_list, "no such file(s)", 1, true) or
       not string.find(file_path_list, "file(s) not in client view", 1, true) then

      local chunks = {}

      for string in file_path_list:gmatch("%S+") do
        table.insert(chunks, string)
      end

      result.valid = true
      result.depot = chunks[1]
      result.client = chunks[2]
      result.host = chunks[3]
    end

    table.insert(result_list, result)
  end

  return result_list
end

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Where_Options P4 command options.
--- @return P4_Command_Where P4_Command_Where P4 command.
function P4_Command_Where:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Where: new")

  local command = {
    "p4",
    "where",
  }

  vim.list_extend(command, file_spec_list)

  --- @type P4_Command_Where
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Where)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Where_Result[]|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_Where:run()

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_Where:_process_response(sc.stdout)
  end

  return success
end

return P4_Command_Where
