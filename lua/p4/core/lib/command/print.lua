local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Print_Options : table

--- @class P4_Command_Print_Result
--- @field file_output_list P4_File_Output[] Each file's output that has been queried from the P4 server.

--- @class P4_Command_Print : P4_Command
--- @field file_specs File_Spec[] File path list
--- @field opts P4_Command_Print_Options Command options.
local P4_Command_Print = {}

P4_Command_Print.__index = P4_Command_Print

setmetatable(P4_Command_Print, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_Print_Result result Hold's the parsed result from the command output.
function P4_Command_Print:_process_response(output)
  log.trace("P4_Command_Print: process_response")

  --- @type P4_Command_Print_Result
  local result = {
    file_output_list = {}
  }

  -- Output is a list of json tables for each file.
  local json_table_list = vim.split(output, "\n", {trimempty = true})

  for _, json_table in ipairs(json_table_list) do

    local output_table = vim.json.decode(json_table)

    if output_table["action"] then
      table.insert(result.file_output_list, output_table)
    elseif output_table["data"] then
      if output_table["data"] ~= "" then
        if result.file_output_list[#result.file_output_list].output then
          result.file_output_list[#result.file_output_list].output = result.file_output_list[#result.file_output_list].output .. output_table["data"]
        else
          result.file_output_list[#result.file_output_list].output = output_table["data"]
        end
      end
    end
  end

  assert(#self.file_specs == #result.file_output_list, "Unexpected number of results.")

  return result
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] One or more file paths.
--- @param opts? P4_Command_Print_Options P4 command options.
--- @return P4_Command_Print P4_Command_Print P4 command.
function P4_Command_Print:new(file_specs, opts)
  opts = opts or {}

  log.trace("P4_Command_Print: new")

  local command = {
    "p4",
    "-Mj",
    "-Ztag",
    "print",
    "-q", --Suppress the one line header added by perforce.
  }

  self.file_specs = file_specs

  vim.list_extend(command, file_specs)

  --- @type P4_Command_Print
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Print)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Print_Result? result Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Print:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_Print:_process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Print
