---@diagnostic disable:unused-local

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

---@diagnostic enable:unused-local

---@class P4_JSON_Error_Table
---@field data string Command output
---@field generic integer Command output
---@field severity integer Severity of the error

---@class P4_Command_Result_Error
---@field data string Data received from the P4 server
---@field generic integer Generic level for the error received from the P4 server
---@field severity integer Severity level for the error received from the P4 server
local P4_Command_Result_Error = {}

P4_Command_Result_Error.__index = P4_Command_Result_Error

--- Wrapper function to check if a table is an instance of this class.
function P4_Command_Result_Error:_check_instance()
  assert(P4_Command_Result_Error.is_instance(self) == true, "Not a P4 command result error class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Command_Result_Error:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Command_Result_Error then
      return true
    end
  end

  return false
end

--- Creates a new P4 command error result.
---
--- @param table P4_JSON_Error_Table
--- @return P4_Command_Result_Error P4_Command_Result_Error A new P4 command result
function P4_Command_Result_Error:new(table)
  local new = setmetatable(table, P4_Command_Result_Error)

  ---@cast new P4_Command_Result_Error
  return new
end

--- Returns the P4 server output for error.
---
--- @return string reason Output reason for the error
function P4_Command_Result_Error:get_reason()
  return self.data
end

--- Returns if the error occured because the user was not logged in.
---
--- @return boolean result If this is the error that occured.
function P4_Command_Result_Error:is_not_logged_in()
  return self.severity == P4_SEVERITY_FAILED and self.generic == P4_GENERIC_CONFIG
end

--- Returns if the error occured because the user was not logged in.
---
--- @return boolean result If this is the error that occured.
function P4_Command_Result_Error:is_invalid_password()
  return self.severity == P4_SEVERITY_FAILED and self.generic == P4_GENERIC_ILLEGAL
end

--- Returns if the error occured because the file does not exist on the P4 server.
---
--- @return boolean result If this is the error that occured.
function P4_Command_Result_Error:is_file_does_not_exist()
  return self.severity == P4_SEVERITY_WARN and self.generic == P4_GENERIC_EMTPY
end

--- Returns if the error occured because the file is not in the client view.
---
--- @return boolean result If this is the error that occured.
function P4_Command_Result_Error:is_not_in_client_view()
  return self.severity == P4_SEVERITY_WARN and self.generic == P4_GENERIC_EMTPY
end

return P4_Command_Result_Error
