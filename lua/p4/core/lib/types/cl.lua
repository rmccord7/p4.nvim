local Enum = require("p4.core.lib.types.enum")

--- @enum P4_CL_STATUS_TYPE
local P4_CL_STATUS_TYPE = Enum {
  "PENDING",
  "SUBMITTED",
  "SHELVED",
}

--- @class P4_CL_Information
--- @field name string CL name.
--- @field user string CL user.
--- @field client_name string CL Client's name.
--- @field description string CL description.
--- @field status P4_CL_STATUS_TYPE CL status.

--- @class P4_CL_Types : table
local P4_CL_Types = {
  status = P4_CL_STATUS_TYPE
}

--- Creates a new CL status enum.
---
--- @param status string
--- @return P4_CL_STATUS_TYPE type CL status type.
function P4_CL_Types.status(status)

  --- @type P4_CL_STATUS_TYPE
  local result

  if status == "pending" then
    result = P4_CL_STATUS_TYPE.PENDING
  elseif status == "submitted" then
    result = P4_CL_STATUS_TYPE.SUBMITTED
  else
    result = P4_CL_STATUS_TYPE.SHELVED
  end

  return result
end

return P4_CL_Types
