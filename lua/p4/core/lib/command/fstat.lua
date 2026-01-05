local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

-- Lua 5.1 compatibility

-- selene: allow(incorrect_standard_library_use)
if not table.unpack then
  table.unpack = unpack
end

--- @class P4_Command_FStat_Options

--- @class P4_Command_FStat_Result
--- @field file_info_list P4_File_Info[]

--- @class P4_Command_FStat : P4_Command
--- @field file_specs File_Spec[] File path list
--- @field opts P4_Command_FStat_Options Command options.
local P4_Command_FStat = {}

P4_Command_FStat.__index = P4_Command_FStat

setmetatable(P4_Command_FStat, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_FStat_Result result Hold's the parsed result from the command output.
function P4_Command_FStat:_process_response(output)
  log.trace("P4_Command_FStat: process_response")

  --- @type P4_Command_FStat_Result
  local result = {
    file_info_list = {}
  }

  -- Output is a list of json tables for each file.
  local file_fstat_list = vim.split(output, "\n", {trimempty = true})

  assert(#self.file_specs == #file_fstat_list, "Unexpected number of output entries.")

  for _, fstat in ipairs(file_fstat_list) do

    local file_info = vim.json.decode(fstat)

    -- Make path relative to the current client root if we are mapped.
    --TODO: Move this to caller for cases where we care about the current client
    if file_info.clientFile and file_info.isMapped then
      local P4_Context = require("p4.context")

      local current_client = P4_Context.get_current_client()

      if current_client then

        local success, spec = current_client:get_spec()

        if success and spec then

          -- Try client root.
          local path = vim.fs.relpath(spec.root, file_info.clientFile)

          if path then
            file_info.clientFile = path
          else
            -- If that fails try alternate roots for a match.
            for _, root in ipairs(spec.alt_root) do

              path = vim.fs.relpath(root, file_info.clientFile)

              if path then
                file_info.clientFile = path
                break
              end
            end
          end
        end
      end
    end

    table.insert(result.file_info_list, file_info)
  end

  assert(#self.file_specs == #result.file_info_list, "Unexpected number of results.")

  return result
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] One or more file paths.
--- @param opts? P4_Command_FStat_Options P4 command options.
--- @return P4_Command_FStat P4_Command_FStat P4 command.
function P4_Command_FStat:new(file_specs, opts)
  opts = opts or {}

  log.trace("P4_Command_FStat: new")

  local command = {
    "p4",
    "-Mj", --Json output format
    "fstat",
  }

  self.file_specs = file_specs

  vim.list_extend(command, file_specs)

  --- @type P4_Command_FStat
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_FStat)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_FStat_Result? result Holds the result if the function was successful.
---
--- @nodiscard
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
