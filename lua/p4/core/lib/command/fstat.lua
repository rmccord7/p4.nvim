local log = require("p4.log")

--- @class P4_Command_FStat_Options : table

--- @class P4_Command_FStat_Result : table
--- @field clientFile P4_Host_File_Path Local path to the file.
--- @field depotFile P4_Depot_File_Path Depot path to the file.
--- @field isMapped boolean Indicates if file is mapped to the current client workspace.
--- @field shelved boolean Indicates if file is shelved.
--- @field change string Open change list number if file is opened in client workspace.
--- @field headRev integer Head revision number if in depot.
--- @field haveRev integer Revision last synced to workpace.
--- @field workRev integer Revision if file is opened.
--- @field action string Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).

--- @class P4_Command_FStat : P4_Command
--- @field opts P4_Command_FStat_Options Command options.
local P4_Command_FStat = {}

--- Creates the P4 command.
---
--- @param file_path_list P4_File_Spec[] One or more file paths.
--- @param opts? P4_Command_FStat_Options P4 command options.
--- @return P4_Command_FStat P4_Command_FStat P4 command.
function P4_Command_FStat:new(file_path_list, opts)
  opts = opts or {}

  log.trace("P4_Command_FStat: new")

  P4_Command_FStat.__index = P4_Command_FStat

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_FStat, {__index = P4_Command})

  local command = {
    "p4",
    "fstat",
  }

  vim.list_extend(command, file_path_list)

  --- @type P4_Command_FStat
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_FStat)

  return new
end

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_FStat_Result[] result Hold's the parsed result from the command output.
function P4_Command_FStat:process_response(output)

  log.trace("P4_Command_FStat: process_response")

  --- @type P4_Command_FStat_Result[]
  local result_list = {}

  for index, file_stats in ipairs(vim.split(output, "\n\n")) do

    -- Last iteration will be empty.
    if file_stats ~= '' then

      --- @type P4_Command_FStat_Result
      local result = {
        clientFile = '',
        depotFile = '',
        action = '',
        change = '',
        haveRev = 0,
        headRev = 0,
        isMapped = false,
        shelved = false,
        workRev = 0,
      }

      for _, line in ipairs(vim.split(file_stats, "\n")) do

        local t = vim.split(line, ' ')

        if t[1] == "..." then

          -- Only store level one values for now.
          if t[2] ~= "..." then
            result[t[2]] = t[3]

            -- Make path relative to the CWD.
            if t[2] == "clientFile" then
              --- @diagnostic disable-next-line No annotation for cwd()
              result[t[2]] = t[3]:gsub(vim.uv.cwd(), '.')
            end
          end
        end
      end

      result_list[index] = result
    end
  end

  return result_list
end

return P4_Command_FStat
