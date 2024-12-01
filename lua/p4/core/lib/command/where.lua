local log = require("p4.log")

--- @class P4_Where : table
--- @field clientFile string Local path to the file in local syntax
--- @field DepotFile string Depot path to the file
--- @field path string Local path to the file

--- @class P4_Command_Where_Options : table

--- @class P4_Command_Where_Result : P4_Where

--- @class P4_Command_Where : P4_Command
--- @field opts P4_Command_Where_Options Command options.
local P4_Command_Where = {}

--- Creates the P4 command.
---
--- @param file_paths string|string[] One or more file paths.
--- @param opts? P4_Command_Where_Options P4 command options.
--- @return P4_Command_Where P4_Command_Where P4 command.
function P4_Command_Where:new(file_paths, opts)
  opts = opts or {}

  P4_Command_Where.__index = P4_Command_Where

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Where, {__index = P4_Command})

  local command = {
    "p4",
    "where",
  }

  if type(file_paths) == "string" then
    table.insert(command, file_paths)
  else
    vim.list_extend(command, file_paths)
  end

  --- @type P4_Command_Where
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Where)

  return new
end

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @param p4_file_list? P4_File[] Optional list of P4 files to update in place.
--- @return P4_Command_Where_Result[] result Hold's the parsed result from the command output.
function P4_Command_Where:process_response(output, p4_file_list)

  --- @type P4_Command_Where_Result[]
  local result = {}

  for index, file_paths in ipairs(vim.split(output, "\n")) do

    -- Result contains "depot_path client_path file_path"
    local chunks = {}

    -- Convert to table
    for string in file_paths:gmatch("%S+") do
      table.insert(chunks, string)
    end

    --- @type P4_File_Path
    local path = {
      depot = chunks[1],
      client = chunks[2],
      host = chunks[3],
    }

    result[index] = path

    if p4_file_list then
      p4_file_list[index].path = path
    end
  end

  return result
end

return P4_Command_Where
