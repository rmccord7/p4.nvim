local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

-- Lua 5.1 compatibility

-- selene: allow(incorrect_standard_library_use)
if not table.unpack then
  table.unpack = unpack
end

--- @class P4_Command_FStat_Options : table

--- @class P4_Command_FStat_Result : table
--- @field valid boolean Indicates if the entry is valid.
--- @field clientFile Client_File_Path? Local path to the file.
--- @field depotFile Depot_File_Path? Depot path to the file.
--- @field isMapped boolean? Indicates if file is mapped to the current client workspace.
--- @field shelved boolean? Indicates if file is shelved.
--- @field change string? Open change list number if file is opened in client workspace.
--- @field headRev integer? Head revision number if in depot.
--- @field haveRev integer? Revision last synced to workpace.
--- @field workRev integer? Revision if file is opened.
--- @field action string? Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).

--- @class P4_Command_FStat : P4_Command
--- @field file_path_list File_Spec[] File path list
--- @field opts P4_Command_FStat_Options Command options.
local P4_Command_FStat = {}

P4_Command_FStat.__index = P4_Command_FStat

setmetatable(P4_Command_FStat, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_FStat_Result[] result Hold's the parsed result from the command output.
function P4_Command_FStat:_process_response(output)
  log.trace("P4_Command_FStat: process_response")

  --- @type P4_Command_FStat_Result[]
  local result_list = {}

  -- Convert spec to table
  local lines = vim.split(output, "\n", {trimempty = true})

  local index = 1

  while index < #lines do

    ---@type P4_Command_FStat_Result
    local result = {
      valid = false
    }

    -- Handle files that are not in the depot or not opened in the client workspace.
    if string.find(lines[index], "no such file(s)", 1, true) or
      string.find(lines[index], "file(s) not in client view", 1, true)then

      table.insert(result_list, result)

      index = index + 1
    else
      if string.find(lines[index], "... depotFile", 1, true) then

        result.valid = true

        local start_index = index

        index = index + 1

        -- End will be reached once the next change is found or we have
        -- reached the end of the output.
        while index < #lines and
          not string.find(lines[index], "no such file(s)", 1, true) and
          not string.find(lines[index], "file(s) not in client view", 1, true) and
          not string.find(lines[index], "... depotFile", 1, true) do
          index = index + 1
        end

        local end_index = index - 1

        -- selene: allow(incorrect_standard_library_use)
        local current_lines = {table.unpack(lines, start_index, end_index)}

        for _, line in ipairs(current_lines) do

          local t = vim.split(line, ' ')

          if t[1] == "..." then

            -- Only store level one values for now.
            if t[2] ~= "..." then
              if t[3] ~= "" then
                ---@diagnostic disable-next-line:assign-type-mismatch
                result[t[2]] = t[3]
              else
                result[t[2]] = true
              end
            end
          end
        end

        -- Make path relative to the current client root.
        if result.isMapped and result.isMapped == true then
          local P4_Context = require("p4.context")

          local current_client = P4_Context.get_current_client()

          if current_client then

            local success, spec = current_client:get_spec()

            if success and spec then
              --TODO: Handle alt root if necessary

              ---@diagnostic disable-next-line:param-type-mismatch
              result.clientFile = vim.fs.relpath(spec.root, result.clientFile)
            end
          end
        end
      else
        assert(false, "Invalid starting line")
      end

      table.insert(result_list, result)
    end
  end

  assert(#self.file_path_list == #result_list, "Incorrect number of expected results.")

  return result_list
end

--- Creates the P4 command.
---
--- @param file_path_list File_Spec[] One or more file paths.
--- @param opts? P4_Command_FStat_Options P4 command options.
--- @return P4_Command_FStat P4_Command_FStat P4 command.
function P4_Command_FStat:new(file_path_list, opts)
  opts = opts or {}

  log.trace("P4_Command_FStat: new")

  local command = {
    "p4",
    "fstat",
  }

  self.file_path_list = file_path_list

  vim.list_extend(command, file_path_list)

  --- @type P4_Command_FStat
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_FStat)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_FStat_Result[]|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_FStat:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_FStat:_process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_FStat
