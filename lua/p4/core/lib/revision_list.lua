local log = require("p4.log")

--- @class P4_Revision_List : table
--- @field private file_spec File_Spec P4 file.
--- @field private list P4_Revision[] P4 client list.
local P4_Revision_List = {}

P4_Revision_List.__index = P4_Revision_List

--- Wrapper function to check if a table is an instance of this class.
function P4_Revision_List:_check_instance()
  assert(P4_Revision_List.is_instance(self) == true, "Not a P4 revision list class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
---
--- @async
--- @nodiscard
function P4_Revision_List:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Revision_List then
      return true
    end
  end

  return false
end

--- @class P4_New_Revision_List_Information
--- @field numbers string[] Revision numbers.
--- @field changes string[] Revision CLs.
--- @field actions string[] Revision actions.
--- @field dates string[] Revision dates.

--- Creates a new P4 revision list.
---
--- @param file_spec File_Spec
--- @return P4_Revision_List P4_Revision_List A new file revision.
--- @nodiscard
function P4_Revision_List:new(file_spec)
  log.trace("P4_Revision_List (new): Enter")

  ---@class P4_Revision_List
  local new = setmetatable({}, P4_Revision_List)

  new.file_spec = file_spec

  -- Issue P4 filelog command to request the specified file's history.
  local P4_Command_FileLog = require("p4.core.lib.command.filelog")

  local success, result_list = P4_Command_FileLog:new({file_spec}):run()

  if success then

    --- @cast result_list P4_Command_Filelog_Result[]

    --- @type P4_Revision[]
    new.list = {}

    local P4_Revision = require("p4.core.lib.revision")

    for _, revision in ipairs(result_list[1].revision_list) do

      --- @cast revision P4_Command_Filelog_Revision

      local P4_CL = require("p4.core.lib.cl")
      local P4_Client = require("p4.core.lib.client")

      --- @type P4_New_CL_Information
      local new_cl_info = {
        name = revision.id,
        client = P4_Client:new(revision.client),
        user = revision.user,
        description = revision.description,
        --FIX: Make status string
        status = P4_CL.status_type.SUBMITTED,
      }

      --- @type P4_New_Revision_Information
      local new_revision_info = {
        revision = revision.revision,
        cl = P4_CL:new(new_cl_info),
        action = revision.action,
        date = revision.date.date,
      }

      local p4_revision = P4_Revision:new(new_revision_info)

      table.insert(new.list, p4_revision)
    end
  end

  log.trace("P4_Revision_List (new): Exit")

  return new
end

--- Returns the list of P4 clients.
---
--- @return P4_Revision[] result A list of P4 clients.
function P4_Revision_List:get()
  log.trace("P4_Revision_List: get")

  return self.list
end

return P4_Revision_List
