---@module "nio"

local cmd_lib = require("p4.core.lib.command")

local error_api = require("p4.api.error")

--- @class P4_Revision
--- @field index string Identifies the revision for all branches (Head revision is 1).
--- @field number string Identifies the revision for this branch (Tail revision is 1). P4 branch history will re-use revision numbers for each branch.
--- @field depotFile Depot_File_Path Name of the file in the depot for this revision.
--- @field action string Action.
--- @field change string Identifies the CL.
--- @field user string Identifies the user.
--- @field client string Identifies the client.
--- @field time string Time/date revision was integrated.
--- @field description string Description from associated CL.

--- @class P4_Command_Filelog_Result_Success : P4_Command_Common_Result_Success, P4_Revision
--- @field rev_list P4_Revision[] List of revisions.

--- @class P4_Command_Filelog_Result_Error
--- @field reason string? Error reason.

--- @class P4_Command_Filelog_Result : P4_Command_Common_Result
--- @field success boolean Indicates if the result is success.
--- @field data P4_Command_Filelog_Result_Success | P4_Command_Filelog_Result_Error Hold's information about the result.

--- @class P4_Command_Filelog : P4_Command
local P4_Command_Filelog = {}

P4_Command_Filelog.__index = P4_Command_Filelog

setmetatable(P4_Command_Filelog, { __index = cmd_lib })

--- Wrapper function to check if a table is an instance of this class.
---
--- @package
function P4_Command_Filelog:_check_instance()
  assert(self:is_instance() == true, "Not a class instance")
end

--- Helper function to process a command result success.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param new_result P4_Command_Filelog_Result New result.
--- @param results P4_Command_Filelog_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Filelog:_cmd_result_success_handler(cmd_result, new_result, results)
  local cmd_result_success = cmd_result.data

  ---@cast cmd_result_success P4_Command_Filelog_Result_Success

  local changes = {} ---@type table<integer, string>[]
  local actions = {} ---@type table<integer, string>[]
  local clients = {} ---@type table<integer, string>[]
  local descriptions = {} ---@type table<integer, string>[]
  local revisions = {} ---@type table<integer, string>[]
  local times = {} ---@type table<integer, string>[]
  local users = {} ---@type table<integer, string>[]

  local function sort(t)
    table.sort(t, function(a,b)
      return a[1] < b[1]
    end)
  end

  for k, v in pairs(cmd_result_success) do
    if k:find("change", 1, true) then
      table.insert(changes, {tonumber(k:match("%d+")), v})
    elseif k:find("^action") then
      table.insert (actions, {tonumber(k:match("%d+")), v})
    elseif k:find("^client") then
      table.insert (clients, {tonumber(k:match("%d+")), v})
    elseif k:find("^desc") then
      table.insert (descriptions, {tonumber(k:match("%d+")), v})
    elseif k:find("^rev") then
      table.insert (revisions, {tonumber(k:match("%d+")), v})
    elseif k:find("^time") then
      table.insert (times, {tonumber(k:match("%d+")), v})
    elseif k:find("^user") then
      table.insert (users, {tonumber(k:match("%d+")), v})
    end
  end

  assert(#changes == #actions and
         #changes == #clients and
         #changes == #descriptions and
         #changes == #revisions and
         #changes == #times and
         #changes == #users,
       "Parse error")

  sort(changes)
  sort(actions)
  sort(clients)
  sort(descriptions)
  sort(revisions)
  sort(times)
  sort(users)

  local count = #new_result.data.rev_list

  for index = 1, #revisions, 1 do

    count = count + 1

    ---@type P4_Revision
    local new_revision = {
      index = count,
      number = revisions[index][2],
      depotFile = cmd_result_success.depotFile,
      action = actions[index][2],
      change = changes[index][2],
      user = users[index][2],
      client = clients[index][2],
      time = times[index][2],
      description = descriptions[index][2],
    }

    table.insert(new_result.data.rev_list, new_revision)
  end

  -- If the first revision didn't add the file, then we need to continue to follow the branch history.
  local last_revision = new_result.data.rev_list[#new_result.data.rev_list]

  -- Determine if this is the last revision for this file. If not an we are following the branch history, then the
  -- next JSON table is the next revision list or branched history for this file and we need to insert it into the
  -- current list.
  if last_revision.action == "add" then
    table.insert(results, new_result)

    -- Next JSON table will be for a new file's history if it exists.
    new_result = {
      success = true,
      data = {
        rev_list = {}
      }
    }
  end
end

--- Helper function to process a command result error.
---
--- @param cmd_result P4_Command_Common_Result Current command result.
--- @param results P4_Command_Filelog_Result[] Hold's the filtered results.
---
--- @package
function P4_Command_Filelog:_cmd_result_error_handler(cmd_result, results)
  -- A file that is not in the client view (generic: 17, severity: 2).
  local function error_is_not_in_client_view(severity, generic)
    if severity == P4_SEVERITY_WARN and generic == P4_GENERIC_EMTPY then
      return true
    end
    return false
  end

  -- A file that is not in the depot (generic: 17, severity: 2).
  local function error_is_not_in_depot(severity, generic)
    if severity == P4_SEVERITY_FAILED and generic == P4_GENERIC_UNKNOWN then
      return true
    end
    return false
  end

  ---@type P4_Command_Result_Error
  local cmd_result_error = cmd_result.data.error

  local severity = cmd_result_error:get_severity()
  local generic = cmd_result_error:get_severity()

  -- Check if we can pass the error up to the caller.
  if error_is_not_in_client_view(severity, generic) or
     error_is_not_in_depot(severity, generic) then

    --- @type P4_Command_Filelog_Result
    result = {
      success = false,
      data = {
        depotFile = vim.split(cmd_result_error.data, " - ", {plain = true})[1],
        reason = vim.split(cmd_result_error.data, " - ", {plain = true})[2],
      }
    }

    table.insert(results, result)
  else

    -- We didn't handle this case or something really bad happened.

    --- @type P4_API_Command_Error
    local new_cmd_error = {
      name = cmd:get_command_name(),
      command = cmd:get_command(),
      results = cmd_result,
    }

    error(error_api:new(P4_RESULT_CODE_COMMAND_FAILED, new_cmd_error))
  end
end

--- Parses the output of the P4 command.
---
--- @param sc vim.SystemCompleted Parsed command result.
--- @return P4_Command_Filelog_Result[] results Hold's the formatted command result.
---
--- @nodiscard
function P4_Command_Filelog:_process_response(sc)
  local cmd_results = cmd_lib._process_response(self, sc)

  -- P4 errors have already been processed. Success results are command dependent and may need further processing ince
  -- there may be some entries that need to be filtered out as information messages or treated as errors.

  --- @type P4_Command_Filelog_Result[]
  local results = {}

  -- For success we cannot add a new result until we reach the last revision that has the action "add". This may span
  -- multple lua tables if we are following the branch history.
  ---@type P4_Command_Filelog_Result
  local new_result = {
    success = true,
    data = {
      rev_list = {}
    }
  }

  -- If we are following a file's branch history, then there will be multiple filelogs JSON tables for a single file.
  -- Each filelog corresponds to a revision list for each time the history branched.
  for _, cmd_result in ipairs(cmd_results) do
    if cmd_result.success then
      self:_cmd_result_success_handler(cmd_result, new_result, results)
    else
      self:_cmd_result_error_handler(cmd_result, results)
    end
  end

  return results
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @return P4_Command_Filelog P4_Command_Filelog P4 command.
function P4_Command_Filelog:new(file_specs)
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

  local new = cmd_lib:new(info)

  --- @cast new P4_Command_Filelog

  setmetatable(new, P4_Command_Filelog)

  return new
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @nodiscard
function P4_Command_Filelog:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_Command_Filelog then
      return true
    end
  end

  return false
end

--- Runs the P4 command.
---
--- @return P4_Command_Filelog_Result[] results Holds the result if the function was successful.
---
--- @nodiscard
--- @async
function P4_Command_Filelog:run()
  self:_check_instance()

  local results = {}
  local success, sc = pcall(cmd_lib.run(self).wait)

  if success then
    if sc then
      results = self:_process_response(sc)
    else
      success = false
    end
  else
    local cmd_error = {
      name = self.name,
      command = self.command,
      results = results,
    }

    error(error_api:new(P4_RESULT_CODE_COMMAND_FAILED, cmd_error))
  end

  return results
end

return P4_Command_Filelog
