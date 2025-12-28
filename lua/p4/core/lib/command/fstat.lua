local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

-- Lua 5.1 compatibility

-- selene: allow(incorrect_standard_library_use)
if not table.unpack then
  table.unpack = unpack
end

--- @class P4_Command_FStat_Options : table

--- @class P4_Command_FStat_Result : table
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

  -- Output is a list of json tables for each file.
  local file_fstat_list = vim.split(output, "\n", {trimempty = true})

  assert(#self.file_path_list == #file_fstat_list, "Unexpected number of output entries.")

  for _, fstat in ipairs(file_fstat_list) do

    local result = vim.json.decode(fstat)

    -- Make path relative to the current client root.
    --TODO: Move this to caller for cases where we care about the current client
    if result.clientFile and result.isMapped then
      local P4_Context = require("p4.context")

      local current_client = P4_Context.get_current_client()

      if current_client then

        local success, spec = current_client:get_spec()

        if success and spec then
          --TODO: Handle alt root?

          result.clientFile = vim.fs.relpath(spec.root, result.clientFile)
        end
      end
    end

    table.insert(result_list, result)
  end

  assert(#self.file_path_list == #result_list, "Unexpected number of results.")

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
    "-Mj", --Json output format
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
