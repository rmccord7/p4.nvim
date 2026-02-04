local log = require("p4.log")

local path_local_lib = require("p4.core.lib.path_local")
local path_client_lib = require("p4.core.lib.path_client")
local path_depot_lib = require("p4.core.lib.path_depot")

--- @class P4_File_Revision
--- @field depot_file Depot_File_Path Depot path to the file.
--- @field number string Revision number.
--- @field action string CL Action.
--- @field cl string CL ID.
--- @field user string CL user.
--- @field client string Name of the client associated with the CL.
--- @field date P4_Command_Describe_Result_Date_Time CL submission date/time.
--- @field description string CL description.

--- @class P4_File_Path
--- @field host P4_Path_Local? Local file path.
--- @field client P4_Path_Client? Client file path.
--- @field depot P4_Path_Depot? Depot file path.
---
--- At least one of host, cilent or depot fields must be valid.

--- @class P4_File_Path_Strings
--- @field host Local_File_Path? Local file path.
--- @field client Client_File_Path? Client file path.
--- @field depot Depot_File_Path? Depot file path.
---
--- At least one of host, cilent or depot fields must be valid.

--- @class P4_File_Info
--- @field path P4_File_Path_Strings File path. Local file path, depot file path, or both.
--- @field action string? Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field shelved boolean? Indicates if file is shelved.
--- @field change string? Open change list number if file is opened in client workspace.
--- @field head_rev string? Head revision number if in depot.
--- @field have_rev string? Revision last synced to workpace.
--- @field work_rev string? Revision if file is opened.
--- @field user string? User.
--- @field rev string? Revision.
--- @field time string? Time.
--- @field file_size string? File size.
--- @field output string? File output.

--- @class P4_Get_File_Info
--- @field path File_Path File path.
--- @field action string? Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field shelved boolean? Indicates if file is shelved.
--- @field change string? Open change list number if file is opened in client workspace.
--- @field head_rev string? Head revision number if in depot.
--- @field have_rev string? Revision last synced to workpace.
--- @field work_rev string? Revision if file is opened.
--- @field user string? User.
--- @field rev string? Revision.
--- @field time string? Time.
--- @field file_size string? File size.
--- @field output string? File output.

--- @class P4_File
--- @field protected path P4_File_Path? File path. Local file path, depot file path, or both.
--- @field protected action string? Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).
--- @field protected shelved boolean? Indicates if file is shelved.
--- @field protected change string? Open change list number if file is opened in client workspace.
--- @field protected head_rev string? Head revision number if in depot.
--- @field protected have_rev string? Revision last synced to workpace.
--- @field protected work_rev string? Revision if file is opened.
--- @field protected rev string? Revision.
--- @field protected time string? Time.
--- @field protected file_size string? File size.
--- @field protected output string? File output.
--- @field protected client? P4_Client P4 client for the current file.
--- @field protected cl? P4_CL P4 CL for the current file.
local P4_File = {}

P4_File.__index = P4_File

--- Wrapper function to check if a table is an instance of this class.
function P4_File:_check_instance()
  assert(P4_File.is_instance(self) == true, "Not a class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_File:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object and object.__index == P4_File then
      return true
    end
  end

  return false
end

--- Creates a new P4 file.
---
--- @param info P4_File_Info File inforamtion.
--- @return P4_File P4_File A new P4 file if this function is successful.
---
--- @nodiscard
function P4_File:new(info)
  vim.validate("info", info, "table")

  assert(info.path and (info.path.host or info.path.depot or info.path.client), "A path must be specified")

  ---@type P4_File
  local new = setmetatable({}, P4_File)

  new.path = {}

  if info.path.host then
    new.path.host = path_local_lib:new(info.path.host)
  end

  if info.path.client then
    new.path.client = path_client_lib:new(info.path.client)
  end

  if info.path.depot then
    new.path.depot = path_depot_lib:new(info.path.depot)
  end

  new.action = info.action
  new.shelved = info.shelved
  new.change = info.change
  new.head_rev = info.head_rev
  new.have_rev = info.have_rev
  new.work_rev = info.work_rev
  new.rev = info.rev
  new.file_size = info.file_size
  new.time = info.time
  new.output = info.output

  return new
end

--- Gets the P4 file's path.
---
--- @return P4_Get_File_Info P4 file path.
---
--- @nodiscard
function P4_File:get_info()
  self:_check_instance()

  return {
    path = (self.path.host and self.path.host.path) or (self.path.depot and self.path.depot.path) or (self.path.client and self.path.client.path),
    action = self.action,
    shelved = self.shelved,
    change = self.change,
    head_rev = self.head_rev,
    have_rev = self.have_rev,
    work_rev = self.work_rev,
    rev = self.rev,
    file_size = self.file_size,
    time = self.time,
    output = self.output,
  }
end

--- Set's the file's information.
---
--- @param info P4_File_Info P4 file info.
function P4_File:update(info)
  self:_check_instance()

  vim.tbl_extend("force", self, info)
end

--- Gets the P4 CL.
---
--- @return P4_CL? P4 CL.
---
--- @nodiscard
function P4_File:get_cl()
  log.trace("P4_File (get_cl): Enter")

  self:_check_instance()

  log.trace("P4_File (get_cl): Exit")

  return(self.cl)
end

--- Sets the P4 CL.
---
--- @param cl P4_CL P4 cl.
function P4_File:set_cl(cl)
  self:_check_instance()

  self.cl = cl
end

--- Gets the P4 Client.
---
--- @return P4_Client? P4 Client.
---
--- @nodiscard
function P4_File:get_client()
  self:_check_instance()

  return(self.client)
end

--- Sets the P4 Client.
---
--- @param client P4_Client P4 client.
function P4_File:set_client(client)
  self:_check_instance()

  self.client = client
end

return P4_File
