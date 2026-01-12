local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Print_Result_Success
--- @field action string Action
--- @field change string Identifies the CL
--- @field depot_file Depot_File_Path Name of the file in the depot for this file
--- @field file_size string Size of the file
--- @field rev string Revision number
--- @field time string Time/date revision was integrated
--- @field output string File output

--- @class P4_Command_Print_Result_Error
--- @field error P4_Command_Result_Error Hold's the error information.

--- @class P4_Command_Print_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Print_Result_Success | P4_Command_Print_Result_Error Hold's information about the result.

--- @class P4_Command_Print : P4_Command
--- @field file_specs File_Spec[] File specs
local P4_Command_Print = {}

P4_Command_Print.__index = P4_Command_Print

setmetatable(P4_Command_Print, {__index = P4_Command})

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Print:_check_instance()
  assert(P4_Command_Print.is_instance(self) == true, "Not a class instance")
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Print_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Print:_process_response(sc)
  log.trace("P4_Command_Print: process_response")

  --- @type P4_Command_Print_Result[]
  local results = {}

  --- Decode the JSON output into lua tables
  local P4_Command_Result = require("p4.core.lib.command.result")

  ---@type P4_Command_Result
  local parsed_output = P4_Command_Result:new(sc)

  -- Can't determine actual number of results until we have parsed the tables due to how P4 outputs results for this
  -- command.
  assert(#parsed_output.tables, "Unexpected number of results")

  -- For each successful file spec this command outputs
  -- "Table with action key (file information)n
  -- "Table with data key (file output)"
  -- "Table with data key (empty string)"
  for _, t in ipairs(parsed_output.tables) do

    local error = false

    for key, _ in pairs(t) do
      if key:find("generic", 1, true) or
        key:find("severity", 1, true)then

        error = true

        local P4_Command_Result_Error = require("p4.core.lib.command.result_error")

        ---@type P4_Command_Print_Result_Error
        local new_error_result = {
          error = P4_Command_Result_Error:new(t)
        }

        ---@type P4_Command_Print_Result
        local new_result = {
          success = false,
          data = new_error_result
        }

        table.insert(results, new_result)
        break
      end
    end

    if not error then

      -- Start of a file spec result
      if t["action"] then

        -- Start a new entry with information about the current file spec.
        ---@type P4_Command_Print_Result
        local new_result = {
          success = true,
          data = t
        }

        table.insert(results, new_result)
      elseif t["data"] then
        -- Sometimes multiple success tables are present with data that needs to be concatenated.
        if t["data"] ~= "" then
          current = results[#results].data

          if current.output then
            current.output = current .. t["data"]
          else
            current.output = t["data"]
          end
        end
      end
    end
  end

  -- Now we can make sure the exact number of results are correct.
  assert(#self.file_specs == #results, "Unexpected number of results.")

  return true, results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @return P4_Command_Print P4_Command_Print P4 command.
---
--- @nodiscard
function P4_Command_Print:new(file_specs)
  opts = opts or {}

  log.trace("P4_Command_Print: new")

  -- Save so we can verify the number of results.
  self.file_specs = file_specs


  local command = {
    "print",
    "-q", --Suppress the one line file header added to the file output by perforce.
  }

  vim.list_extend(command, file_specs)

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  --- @type P4_Command_Print
  local new = P4_Command:new(info)

  setmetatable(new, P4_Command_Print)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Print:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object.__index == P4_Command_Print then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Print_Result[]? results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Print:run()
  self:_check_instance()

  local results = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    if sc then
      success, results = P4_Command_Print:_process_response(sc)
    else
      success = false
    end
  end

  return success, results
end


return P4_Command_Print
