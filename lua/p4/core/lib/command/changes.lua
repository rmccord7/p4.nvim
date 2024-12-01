local log = require("p4.log")

--- @class P4_Command_Changes_Options : table
--- @field client? string Limit CLs to the specified P4 client

--- @class P4_Command_Changes_Result
--- @field name string P4 CL name
--- @field user string CL user.
--- @field client_name string CL Client's name.
--- @field description string CL description.
--- @field status string CL status.

--- @class P4_Command_Changes : P4_Command
--- @field opts P4_Command_Changes_Options Command options.
local P4_Command_Changes = {}

--- Creates the P4 command.
---
--- @param opts? P4_Command_Changes_Options P4 command options.
--- @return P4_Command_Changes P4_Command_Changes P4 command.
function P4_Command_Changes:new(opts)
  opts = opts or {}

  log.trace("P4_Command_Changes: new")

  P4_Command_Changes.__index = P4_Command_Changes

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Changes, {__index = P4_Command})

  local command = {
    "p4",
    "changes",
    "--me", -- Current user
    "-l", -- Long output
    "-s", -- Pending CLs only for now
    "pending",
  }

  if opts.client then

    local ext_cmd = {
      "-c",
      opts.client
    }

    vim.list_extend(command, ext_cmd)
  end

  --- @type P4_Command_Changes
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Changes)

  return new
end

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Changes_Result[] result Hold's the parsed result from the command output.
function P4_Command_Changes:process_response(output)

  log.trace("P4_Command_Changes: process_response")

  --- @type P4_Command_Changes_Result[]
  local result_list = {}

  -- Convert spec to table
  local lines = vim.split(output, "\n")

  local index = 1

  while index < #lines do

    -- If this is a P4 change, then the line starts with 'Change'.
    if string.match(lines[index], "^Change") then

      local chunks = {}
      for substring in lines[index]:gmatch("%S+") do
        table.insert(chunks, substring)
      end

      --- @type P4_Command_Changes_Result
      local result = {
        name = chunks[2],
        user = vim.split(chunks[6], '@')[1],
        client_name = vim.split(chunks[6], '@')[2],
        description = '',
        status = string.gsub(chunks[7], '%*', ''),
      }

      -- Start index will be the next line.
      index = index + 1
      local start_index = index

      -- End will be reached once the next change is found or we have
      -- reached the end of the output.
      while index < #lines and not string.match(lines[index], "^Change") do
        index = index + 1
      end

      local end_index = index

      -- If we found the next change, then the actual end index is the line
      -- before.
      if index ~= #lines then
        end_index = end_index - 1
      end

      result.description = table.concat(lines, '\n', start_index, end_index)

      table.insert(result_list, result)
    else
      index = index + 1
    end
  end

  log.fmt_debug("P4_Command_Changes: Process Response result, %s", result_list)

  return result_list
end

return P4_Command_Changes
