local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Revision
--- @field index integer Identifies the revision across branch history (Head revision is 1).
--- @field number string Identifies the revision for this branch (Tail revision is 1). P4 branch history will re-use revision numbers for each branch.
--- @field depot_file Depot_File_Path Name of the file in the depot for this revision.
--- @field action string Action.
--- @field change string Identifies the CL.
--- @field user string Identifies the user.
--- @field client string Identifies the client.
--- @field time string Time/date revision was integrated.
--- @field description string Description from associated CL.

--- @class P4_Command_Filelog_Result_Success
--- @field rev_list P4_Revision[] List of revisions.

--- @class P4_Command_Filelog_Result_Error
--- @field error P4_Command_Result_Error Hold's the error information.

--- @class P4_Command_Filelog_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Filelog_Result_Success | P4_Command_Filelog_Result_Error Hold's information about the result.

--- @class P4_Command_Filelog : P4_Command
--- @field file_specs File_Spec[] File specs
local P4_Command_Filelog = {}

P4_Command_Filelog.__index = P4_Command_Filelog

setmetatable(P4_Command_Filelog, { __index = P4_Command })

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Filelog:_check_instance()
  assert(P4_Command.is_instance(self) == true, "Not a class instance")
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Filelog_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Filelog:_process_response(sc)
  log.trace("P4_Command_Filelog: process_response")

  --- @type P4_Command_Print_Result[]
  local results = {}

  -- For success we cannot add a new result until we reach the last revision that has the action "add". This may span
  -- multple lua tables if we are following the branch history.
  ---@type P4_Command_Filelog_Result
  local result = {
    success = true,
    data = {
      rev_list = {}
    }
  }

  --- Decode the JSON output into lua tables
  local P4_Command_Result = require("p4.core.lib.command.result")

  ---@type P4_Command_Result
  local parsed_output = P4_Command_Result:new(sc)

  -- Can't determine actual number of results until we have parsed the tables due to how P4 outputs results for this
  -- command.
  assert(#parsed_output.tables, "Unexpected number of results")

  -- If we are following a file's branch history, then there will be multiple filelogs JSON tables for a single file.
  -- Each filelog corresponds to a revision list for each time the history branched.
  for _, t in ipairs(parsed_output.tables) do

    local error = false

    for key, _ in pairs(t) do
      if key:find("generic", 1, true) or
        key:find("severity", 1, true)then

        error = true

        local P4_Command_Result_Error = require("p4.core.lib.command.result_error")

        ---@type P4_Command_Filelog_Result_Error
        local new_error_result = {
          error = P4_Command_Result_Error:new(t)
        }

        ---@type P4_Command_Filelog_Result
        local new_result = {
          success = false,
          data = new_error_result
        }

        table.insert(results, new_result)
        break
      end
    end

    if not error then

      local changes = {} ---@type string[]
      local actions = {} ---@type string[]
      local clients = {} ---@type string[]
      local descriptions = {} ---@type string[]
      local revisions = {} ---@type string[]
      local times = {} ---@type string[]
      local users = {} ---@type string[]

      for key, value in pairs(t) do

        if key:find("change", 1, true) then
          table.insert(changes, value)
        elseif key:find("^action") then
          table.insert (actions, value)
        elseif key:find("^client") then
          table.insert (clients, value)
        elseif key:find("^desc") then
          table.insert (descriptions, value)
        elseif key:find("^rev") then
          table.insert (revisions, value)
        elseif key:find("^time") then
          table.insert (times, value)
        elseif key:find("^user") then
          table.insert (users, value)
        end
      end

      assert(#changes == #actions and
             #changes == #clients and
             #changes == #descriptions and
             #changes == #revisions and
             #changes == #times and
             #changes == #users,
           "Number of revisions should match the number of each field")

      for index = 1, #revisions, 1 do

        --- @type P4_Revision
        local revision = {
          index = #result.data.rev_list + 1,
          number = revisions[index],
          depot_file = t.depot_file,
          action = actions[index],
          change = changes[index],
          user = users[index],
          client = clients[index],
          time = times[index],
          description = descriptions[index],
        }

        table.insert(result.data.rev_list, revision)
      end

      -- If the first revision didn't add the file, then we need to continue to follow the branch history.
      local last_revision = result.data.rev_list[#result.data.rev_list]

      -- Determine if this is the last revision for this file. If not an we are following the branch history, then the
      -- next JSON table is the next revision list or branched history for this file and we need to insert it into the
      -- current list.
      if last_revision.action == "add" then
        table.insert(results, result)

        -- Next JSON table will be for a new file's history if it exists.
        result = {
          success = true,
          data = {
            rev_list = {}
          }
          }
      end
    end
  end

  assert(#self.file_specs == #results, "Unexpected number of results.")

  return true, results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @return P4_Command_Filelog P4_Command_Filelog P4 command.
function P4_Command_Filelog:new(file_specs)
  log.trace("P4_Command_Filelog: new")

  -- Save so we can verify the number of results.
  self.file_specs = file_specs

  local command = {
    "filelog",
    "-i", -- Follow history across branches.
    "-l", -- Full CL description.
    "-t", -- Display the time and date.
  }

  vim.list_extend(command, file_specs)

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
  }

  --- @type P4_Command_Filelog
  local new = P4_Command:new(info)

  setmetatable(new, P4_Command_Filelog)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Print_Result[]? results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Filelog:run()

  local results = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    if sc then
      success, results = P4_Command_Filelog:_process_response(sc)
    else
      success = false
    end
  end

  return success, results
end

return P4_Command_Filelog
