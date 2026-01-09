local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Files_Result_Success
--- @field action string Action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field change string Change list number.
--- @field depotFile Depot_File_Path Depot path.
--- @field rev string Head revision number.
--- @field time string Indicates if file is shelved.

--- @class P4_Command_Files_Result_Error
--- @field error P4_Command_Result_Error Hold's error information.

--- @class P4_Command_Files_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Files_Result_Success | P4_Command_Files_Result_Error Hold's information about the result.

--- @class P4_Command_Files : P4_Command
--- @field file_specs File_Spec[] File specs.
local P4_Command_Files = {}

P4_Command_Files.__index = P4_Command_Files

setmetatable(P4_Command_Files, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Files_Result[] results Hold's the formatted command result.
function P4_Command_Files:_process_response(sc)
  log.trace("P4_Command_Files: process_response")

  --- @type P4_Command_Files_Result[]
  local results = {}

  -- Convert command result which consists of  multiple JSONS entries into lua tables.
  local success, parsed_output = P4_Command._process_response(self, sc)

  if success then

    -- This command can take multiple file specs so we should have a table for each file spec.
    assert(#parsed_output.tables == #self.file_specs, "Incorrect number of results")

    for _, t in ipairs(parsed_output.tables) do

      local error = false

      for key, _ in pairs(t) do
        if key:find("generic", 1, true) or
          key:find("severity", 1, true)then

          error = true

          local P4_Command_Result_Error = require("p4.core.lib.command.result_error")

          ---@type P4_Command_Files_Result_Error
          local new_error_result = {
            error = P4_Command_Result_Error:new(t)
          }

          ---@type P4_Command_Files_Result
          local new_result = {
            success = false,
            data = new_error_result
          }

          table.insert(results, new_result)
          break
        end
      end

      if not error then

          ---@type P4_Command_Files_Result
          local new_result = {
            success = true,
            data = t
          }

        table.insert(results, new_result)
      end
    end
  end

  return success, results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @return P4_Command_Files P4_Command_Files P4 command.
function P4_Command_Files:new(file_specs)
  log.trace("P4_Command_Files: new")

  local command = {
    "p4",
    "-Mj",
    "-ztag",
    "files",
    "-e", -- Exclude deleted files.
  }

  -- Save so we can verify the number of results.
  self.file_specs = file_specs

  vim.list_extend(command, file_specs)

  --- @type P4_Command_Files
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Files)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Files_Result[]? result Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Files:run()

  local results = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    success, results = P4_Command_Files:_process_response(sc)
  end

  return success, results
end

return P4_Command_Files
