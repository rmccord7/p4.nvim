--- @class P4_FStat : table
--- @field clientFile string Local path to the file in local syntax
--- @field DepotFile string Depot path to the file
--- @field path string Local path to the file
--- @field isMapped boolean Indicates if file is mapped to the current client workspace
--- @field shelved boolean Indicates if file is shelved
--- @field change integer Open change list number if file is opened in client workspace
--- @field headRev integer Head revision number if in depot
--- @field haveRev integer Revision last synced to workpace
--- @field workRev integer Revision if file is opened
--- @field action string Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive)

--- @class P4_Command_FStat_Options : table

--- @class P4_Command_FStat_Result : P4_FStat

--- @class P4_Command_FStat : P4_Command
--- @field opts P4_Command_FStat_Options Command options.
local P4_Command_FStat = {}

--- Creates the P4 command.
---
--- @param file_paths string|string[] One or more file paths.
--- @param opts? P4_Command_FStat_Options P4 command options.
--- @return P4_Command_FStat P4_Command_FStat P4 command.
function P4_Command_FStat:new(file_paths, opts)
  opts = opts or {}

  P4_Command_FStat.__index = P4_Command_FStat

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_FStat, {__index = P4_Command})

  local command = {
    "p4",
    "fstat",
  }

  if type(file_paths) == "string" then
    table.insert(command, file_paths)
  else
    vim.list_extend(command, file_paths)
  end

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

  --- @type P4_Command_FStat_Result[]
  local result = {}

  for index, file_stats in ipairs(vim.split(output, "\n\n")) do

    -- Last iteration will be empty.
    if file_stats ~= '' then

      local fstat = {}

      for _, line in ipairs(vim.split(file_stats, "\n")) do

        local t = vim.split(line, ' ')

        if t[1] == "..." then

          -- Only store level one values for now.
          if t[2] ~= "..." then
            fstat[t[2]] = t[3]

            if t[2] == "clientFile" then
              --- @diagnostic disable-next-line No annotation for cwd()
              fstat[t[2]] = t[3]:gsub(vim.uv.cwd(), '.')
            end
          end
        end
      end

      result[index] = fstat
    end
  end

  return result
end

return P4_Command_FStat
