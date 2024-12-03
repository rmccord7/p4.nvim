local log = require("p4.log")

-- Lua 5.1 compatibility

-- selene: allow(incorrect_standard_library_use)
if not table.unpack then
    table.unpack = unpack
end

--- @class P4_Command_Describe_Options : table
--- @field shelved? boolean Lists of files that have been shelved.

--- @class P4_Command_Describe_Result_Date_Time : table
--- @field date string Date
--- @field time string Time

--- @class P4_Command_Describe_Result : table
--- @field name string P4 CL name
--- @field user string CL user.
--- @field client_name string CL Client's name.
--- @field description string CL description.
--- @field created_date P4_Command_Describe_Result_Date_Time CL creation date.
--- @field status string CL status.
--- @field files string[] File list. Each file path is depot path.

--- @class P4_Command_Describe : P4_Command
--- @field opts P4_Command_Describe_Options Command options.
local P4_Command_Describe = {}

--- Creates the P4 command.
---
--- @param cl_list string[] Change lists.
--- @param opts? P4_Command_Describe_Options P4 command options.
--- @return P4_Command_Describe P4_Command_Describe P4 command.
function P4_Command_Describe:new(cl_list, opts)
  opts = opts or {}

  log.trace("P4_Command_Describe: new")

  P4_Command_Describe.__index = P4_Command_Describe

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Describe, {__index = P4_Command})

  local command = {
    "p4",
    "describe",
  }

  -- Specify change list
  if opts.shelved then

    local ext_cmd = {
      "-s", -- Exclude shelved file diffs against have revision.
      "-S", -- Get shelved files.
    }

    vim.list_extend(command, ext_cmd)
  end

  vim.list_extend(command, cl_list)

  --- @type P4_Command_Describe
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Describe)

  return new
end

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Change_Result result Hold's the parsed result from the command output.
function P4_Command_Describe:process_response(output)
  log.trace("P4_Command_Describe: process_response")

  --- @type P4_Command_Describe_Result[]
  local result_list = {}

  local file_marker = ""

  if self.opts.shelved and self.opts.shelved == true then
   file_marker = "Shelved"
  else
   file_marker = "Affected"
  end

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

      --- @type P4_Command_Describe_Result
      local result = {
        name = chunks[2],
        user = vim.split(chunks[4], '@')[1],
        client_name = vim.split(chunks[4], '@')[2],
        description = '',
        created_date = {
          date = chunks[6],
          time = chunks[7],
        },
        status = string.gsub(chunks[8], '%*', ''),
        files = {},
      }

      -- Start index will be the line after the next.
      index = index + 2
      local start_index = index

      -- End will be reached once the next change is found or we have
      -- reached the end of the output.
      while index < #lines and not string.match(lines[index], "^" .. file_marker) do
        index = index + 1
      end

      local end_index = index

      -- If we found the next change, then the actual end index is the line
      -- before.
      if index ~= #lines then
        end_index = end_index - 1
      end

      result.description = table.concat(lines, '\n', start_index, end_index)

      -- Start index will be the next line.
      index = index + 1
      start_index = index

      -- End will be reached once the next change is found or we have
      -- reached the end of the output.
      while index < #lines and not string.match(lines[index], "^Change") do
        index = index + 1
      end

      end_index = index

      -- If we found the next change, then the actual end index is the line
      -- before.
      if index ~= #lines then
        end_index = end_index - 1
      end

      -- selene: allow(incorrect_standard_library_use)
      local t = {table.unpack(lines, start_index, end_index)}

      for _, line in ipairs(t) do

        chunks = {}
        for substring in line:gmatch("%S+") do
          table.insert(chunks, substring)
        end

        table.insert(result.files, vim.split(chunks[2], '#')[1])
      end

      table.insert(result_list, result)
    else
      index = index + 1
    end
  end

  log.fmt_debug("P4_Command_Describe: Process Response result, %s", result_list)

  return result_list
end

return P4_Command_Describe
