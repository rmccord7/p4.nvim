local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Filelog_Options

--- @class P4_Command_Filelog_Result
--- @field revisions P4_Revisions

--- @class P4_Command_Filelog : P4_Command
--- @field file_specs File_Spec[] File specsj
--- @field opts P4_Command_Filelog_Options Command options.
local P4_Command_Filelog = {}

P4_Command_Filelog.__index = P4_Command_Filelog

setmetatable(P4_Command_Filelog, { __index = P4_Command })

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Filelog_Result[] result Hold's the parsed result from the command output.
function P4_Command_Filelog:_process_response(output)
  log.trace("P4_Command_Filelog: process_response")

  --- @type P4_Command_Filelog_Result[]
  local result_list = {}

  -- Output is a list of json tables for each file.
  local file_filelog_list = vim.split(output, "\n", {trimempty = true})

  --- @type P4_Command_Filelog_Result
  local result = {
    revisions = {
      count = 0,
      list = {},
    }
  }

  -- If we are following a file's branch history, then there will be multiple filelogs JSON tables for a single file.
  -- Each filelog corresponds to a revision list for each time the history branched.
  for _, filelog in ipairs(file_filelog_list) do

    local filelog_table = vim.json.decode(filelog)

    local changes = {} ---@type string[]
    local actions = {} ---@type string[]
    local clients = {} ---@type string[]
    local descriptions = {} ---@type string[]
    local revisions = {} ---@type string[]
    local times = {} ---@type string[]
    local users = {} ---@type string[]

    for key, value in pairs(filelog_table) do

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
        index = result.revisions.count + 1,
        number = revisions[index],
        depot_file = filelog_table.depot_file,
        action = actions[index],
        change = changes[index],
        user = users[index],
        client = clients[index],
        time = times[index],
        description = descriptions[index],
      }

      result.revisions.count = result.revisions.count + 1

      table.insert(result.revisions.list, revision)
    end


    -- If the first revision didn't add the file, then we need to continue to follow the branch history.
    local last_revision = result.revisions.list[#result.revisions.list]

    -- Determine if this is the last revision for this file. If not an we are following the branch history, then the
    -- next JSON table is the next revision list or branched history for this file and we need to insert it into the
    -- current list.
    if last_revision.action == "add" then
      table.insert(result_list, result)

      -- Next JSON table will be for a new file's history if it exists.
      result = {
          revisions = {
            count = 0,
            list = {},
          }
        }
    end
  end

  assert(#self.file_specs == #result_list, "Unexpected number of results.")

  return result_list
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @param opts? P4_Command_Filelog_Options P4 command options.
--- @return P4_Command_Filelog P4_Command_Filelog P4 command.
function P4_Command_Filelog:new(file_specs, opts)
  opts = opts or {}

  log.trace("P4_Command_Filelog: new")

  local command = {
    "p4",
    "-Mj",
    "-Ztag",
    "filelog",
    "-i", -- Follow history across branches.
    "-l", -- Full CL description.
    "-t", -- Display the time and date.
  }

  self.file_specs = file_specs

  vim.list_extend(command, file_specs)

  --- @type P4_Command_Filelog
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Filelog)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Filelog_Result[]|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_Filelog:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_Filelog:_process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Filelog
