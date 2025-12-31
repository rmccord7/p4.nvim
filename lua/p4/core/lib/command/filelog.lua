local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Filelog_Options : table

--- @class P4_Command_Result_Result_Date_Time : table
--- @field date string Date
--- @field time string Time

--- @class P4_Command_Filelog_Revision : table
--- @field depot_file P4_Depot_File_Path Depot path to the file.
--- @field number string Revision number.
--- @field action string CL Action.
--- @field id string CL ID.
--- @field user string CL user.
--- @field client string Name of the client associated with the CL.
--- @field date P4_Command_Result_Result_Date_Time CL submission date/time.
--- @field description string CL description.
local P4_Command_Filelog_Revision = {
  depot_file = "",
  revision = "",
  action = "",
  client = "",
  user = "",
  id = "",
  date = {
    date = "",
    time = "",
  }
}

--- @class P4_Command_Filelog_Result : table
--- @field num_revisions integer Number of revisions.
--- @field revision_list P4_Command_Filelog_Revision[] Revision list.
--- @field next P4_Command_Filelog_Result? Next revision list for following branch history past revision #1.

--- @class P4_Command_Filelog : P4_Command
--- @field opts P4_Command_Filelog_Options Command options.
local P4_Command_Filelog = {}

P4_Command_Filelog.__index = P4_Command_Filelog

setmetatable(P4_Command_Filelog, { __index = P4_Command })

--- Creates a new P4 revision.
---
--- @param depot_file string
--- @param lines string[]
--- @param index integer
--- @return P4_Command_Filelog_Revision P4_Command_Filelog_Revision P4 file log revision.
--- @return integer index Updated index.
local function process_revision(depot_file, lines, index)
  log.trace("P4_Command_Filelog: process_revision")

  --- @type P4_Command_Filelog_Revision
  local revision = {
    depot_file = "",
    revision = "",
    action = "",
    client = "",
    user = "",
    id = "",
    date = {
      date = "",
      time = "",
    }
  }

  -- Check if this is a revision.
  if string.match(lines[index], "^... #") then
    -- Read the current line
    local chunks = {}
    for substring in lines[index]:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    revision.depot_file = depot_file
    revision.revision = chunks[2]
    revision.id = chunks[4]
    revision.action = chunks[5]
    revision.user = vim.split(chunks[10], "@")[1]
    revision.client = vim.split(chunks[10], "@")[2]
    revision.date.date = chunks[7]
    revision.date.time = chunks[8]

    -- Start index will be the next line.
    index = index + 1
    local start_index = index

    -- End will be reached once the next change is found or we have
    -- reached the end of the output.
    while index < #lines and not string.match(lines[index], "^... #" or string.match(lines[index], "^//"))do
      index = index + 1
    end

    local end_index = index

    -- If we found the next change, then the actual end index is the line
    -- before.
    if index ~= #lines then
      end_index = end_index - 1
    end

    revision.description = table.concat(lines, '\n', start_index, end_index)
  else
    index = index + 1
  end

  return revision, index
end

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Filelog_Result[] result Hold's the parsed result from the command output.
function P4_Command_Filelog:_process_response(output)
  log.trace("P4_Command_Filelog: process_response")

  --- @type P4_Command_Filelog_Result[]
  local result_list = {}

  -- Convert spec to table
  local lines = vim.split(output, "\n")
  local index = 1

  -- Assume we will insert the result in the list of revisions for each file.
  local insert_list = result_list

  -- New file.
  while index < #lines and string.match(lines[index], "^//") do
    --- @type P4_Command_Filelog_Result
    local result = {
      num_revisions = 0,
      revision_list = {},
      next = nil,
    }

    -- Name of file is the current line.
    local depot_file = lines[index]
    index = index + 1

    local revision

    -- Process all the revisions for this file.
    while index < #lines do
      --- @type P4_Command_Filelog_Revision
      revision, index = process_revision(depot_file, lines, index)

      result.num_revisions = result.num_revisions + 1
      table.insert(result.revision_list, revision)

      -- Last revision is 1.
      if revision.number == "#1" then
        break
      end
    end

    table.insert(insert_list, result)

    -- If the first revision didn't add the file, then we need to continue to follow the branch history.
    if revision.revision == "#1" and revision.action == "add" then
      -- Reset for a new file.
      insert_list = result_list
    else
      -- This file branched from another file with additional revision history.
      insert_list = result.next

      result = {
        num_revisions = 0,
        revision_list = {},
        next = nil,
      }
    end
  end

  return result_list
end

--- Creates the P4 command.
---
--- @param file_spec_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_Filelog_Options P4 command options.
--- @return P4_Command_Filelog P4_Command_Filelog P4 command.
function P4_Command_Filelog:new(file_spec_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Filelog: new")

  local command = {
    "p4",
    "filelog",
    "-i", -- Follow history across branches.
    "-l", -- Full CL description.
    "-t", -- Display the time and date.
  }

  vim.list_extend(command, file_spec_list)

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
