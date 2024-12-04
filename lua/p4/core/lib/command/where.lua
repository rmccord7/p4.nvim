local log = require("p4.log")

--- @class P4_Command_Where_Options : table

--- @class P4_Command_Where_Result : table
--- @field depot P4_Depot_File_Path Depot path to the file
--- @field client P4_Client_File_Path Client path to the file in local syntax
--- @field host P4_Host_File_Path Local path to the file

--- @class P4_Command_Where : P4_Command
--- @field opts P4_Command_Where_Options Command options.
local P4_Command_Where = {}

--- Creates the P4 command.
---
--- @param file_spec_list P4_File_Spec[] One or more file paths.
--- @param opts? P4_Command_Where_Options P4 command options.
--- @return P4_Command_Where P4_Command_Where P4 command.
function P4_Command_Where:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Where: new")

  P4_Command_Where.__index = P4_Command_Where

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Where, {__index = P4_Command})

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

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_Where_Result[] result Hold's the parsed result from the command output.
function P4_Command_Where:process_response(output)

  log.trace("P4_Command_Where: process_response")

  --- @type P4_Command_Where_Result[]
  local result_list = {}

  for _, file_path_list in ipairs(vim.split(output, "\n")) do

    local chunks = {}

    -- Convert to table
    for string in file_path_list:gmatch("%S+") do
      table.insert(chunks, string)
    end

    --- @type P4_Command_Where_Result
    local result = {
      depot = chunks[1],
      client = chunks[2],
      host = chunks[3],
    }

    table.insert(result_list, result)
  end

  return result_list
end

return P4_Command_Where
