local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Files_Options : table

--- @class P4_Command_Files_Result : table
--- @field in_client_view boolean Indicates if the file is in the client view.
--- @field path Depot_File_Path Depot path to the file.
--- @field head_rev string head revision.
--- @field submit_cl string Last P4 CL that corresponds to the head revision.

--- @class P4_Command_Files : P4_Command
--- @field opts P4_Command_Files_Options Command options.
local P4_Command_Files = {}

P4_Command_Files.__index = P4_Command_Files

setmetatable(P4_Command_Files, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_Files_Result[] result Hold's the parsed result from the command output.
function P4_Command_Files:_process_response(output)

  log.trace("P4_Command_Files: process_response")

  --- @type P4_Command_Files_Result[]
  local result_list = {}

  for _, line in ipairs(vim.split(output, "\n\n")) do

    if not string.find(line, "file(s) not in client view", 1, true) then

      local chunks = {}

      -- Convert to table
      for string in line:gmatch("%S+") do
        table.insert(chunks, string)
      end

      --- @type P4_Command_Files_Result
      local result = {
        in_client_view = true,
        path = vim.split(chunks[1], '#')[1],
        head_rev = vim.split(chunks[1], '#')[2],
        submit_cl = chunks[5],
      }

      table.insert(result_list, result)
    else

      --- @type P4_Command_Files_Result
      local result = {
        in_client_view = false,
        path = '',
        head_rev = "1",
        submit_cl = 'Not in depot'
      }

      table.insert(result_list, result)
    end
  end

  return result_list
end

--- Creates the P4 command.
---
--- @param file_path_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Files_Options P4 command options.
--- @return P4_Command_Files P4_Command_Files P4 command.
function P4_Command_Files:new(file_path_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Files: new")

  local command = {
    "p4",
    "files",
    "-e", -- Exclude deleted files.
  }

  vim.list_extend(command, file_path_list)

  --- @type P4_Command_Files
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Files)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Files_Result[]|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_Files:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_Files:_process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Files
