local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")


-- Generic errors
local P4_GENERIC_NONE = 0

-- Generic user errors
local P4_GENERIC_USAGE   = 1 -- request not consistent with dox
local P4_GENERIC_UNKNOWN = 2 -- using unknown entity
local P4_GENERIC_CONTEXT = 3 -- using entity in wrong context
local P4_GENERIC_ILLEGAL = 4 -- trying to do something you can't
local P4_GENERIC_NOT_YET = 5 -- something must be corrected first
local P4_GENERIC_PROJECT = 6 -- protections prevented operation

--Generic errors
local P4_GENERIC_EMTPY = 17 -- action returned empty results

--Generic server errors
local P4_GENERIC_FAULT   = 33 -- inexplicable program fault
local P4_GENERIC_CLIENT  = 34 -- client side program errors
local P4_GENERIC_ADMIN   = 35 -- server administrative action required
local P4_GENERIC_CONFIG  = 36 -- client configuration inadequate
local P4_GENERIC_UPGRADE = 37 -- client or server too old to interact
local P4_GENERIC_COMM    = 38 -- communications error
local P4_GENERIC_TOO_BIG = 39 -- not even Perforce can handle this much

-- Severify errors
local P4_SEVERITY_NONE   = 0
local P4_SEVERITY_IFNO   = 1
local P4_SEVERITY_WARN   = 2
local P4_SEVERITY_FAILED = 3
local P4_SEVERITY_FATAL  = 4

--- @class P4_Command_Files_Options : table

---@class P4_Command_Files_Output_Result
---@field action string Action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
---@field change string Change list number.
---@field depotFile Depot_File_Path Depot path.
---@field rev string Head revision number.
---@field time string Indicates if file is shelved.

--- @class P4_Command_Files_Result
--- @field list P4_Command_Files_Output_Result[]
--- @field errors P4_Command_Output_Error_Result[]

--- @class P4_Command_Files : P4_Command
--- @field file_specs File_Spec[] File specs.
--- @field opts P4_Command_Files_Options Command options.
local P4_Command_Files = {}

P4_Command_Files.__index = P4_Command_Files

setmetatable(P4_Command_Files, {__index = P4_Command})

--- Parses the output of the P4 command.
---
--- @param output string Command output.
--- @return P4_Command_Files_Result result Hold's the parsed result from the command output.
function P4_Command_Files:_process_response(output)
  log.trace("P4_Command_Files: process_response")

  --- @type P4_Command_Files_Result
  local result = {
    list = {},
    errors = {}
  }

  local files_list = vim.split(output, "\n", {trimempty = true})

  for _, file in ipairs(files_list) do

    local info = vim.json.decode(file)

    -- Files that have errors will have the following keys in its table.
    for key, _ in pairs(info) do
      if key:find("data", 1, true) or
        key:find("generic", 1, true) or
        key:find("severity", 1, true)then

        table.insert(result.errors, info)
        break
      else
        table.insert(result.list, info)
        break
      end
    end
  end

  assert(#result.list + #result.errors == #self.file_specs)

  return result
end

--- Creates the P4 command.
---
--- @param file_specs File_Spec[] File specs.
--- @param opts? P4_Command_Files_Options P4 command options.
--- @return P4_Command_Files P4_Command_Files P4 command.
function P4_Command_Files:new(file_specs, opts)
  opts = opts or {}

  log.trace("P4_Command_Files: new")

  local command = {
    "p4",
    "-Mj",
    "-ztag",
    "files",
    "-e", -- Exclude deleted files.
  }

  self.file_specs = file_specs

  vim.list_extend(command, file_specs)

  --- @type P4_Command_Files
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Files)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Files_Result? result Holds the result if the function was successful.
--- @async
function P4_Command_Files:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_Files:_process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Files
