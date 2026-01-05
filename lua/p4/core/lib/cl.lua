local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_CL_Spec_Date_Time : table
--- @field date string Date
--- @field time string Time

--- @class P4_CL_Spec : table
--- @field output string Read change spec output.
--- @field change string CL change number
--- @field date P4_CL_Spec_Date_Time Last modified date
--- @field client string Name of client that owns the CL
--- @field user string User that owns the CL
--- @field status string Either 'pending' or 'submitted'
--- @field type string Either 'public' or 'restricted'
--- @field description string CL description
--- @field imported_by string CL description
--- @field identity string CL description
--- @field jobs string CL description
--- @field stream string CL description
--- @field file_path_list File_Path[] List of files checked out for this CL

--- @class P4_CL : table
--- @field protected change string P4 CL name
--- @field protected spec P4_CL_Spec CL spec
--- @field protected client? P4_Client CL Client
--- @field protected file_list? P4_File_List List of P4 files that are open for the CL
local P4_CL = {}

P4_CL.__index = P4_CL

--- Wrapper function to check if a table is an instance of this class.
function P4_CL:_check_instance()
  assert(P4_CL.is_instance(self) == true, "Not a P4 CL class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_CL:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_CL then
      return true
    end
  end

  return false
end

--- @class P4_New_CL_Information
--- @field change string CL name.
--- @field client P4_Client? Optional P4 client.
--- @field file_list P4_File_List? Optional P4 file list.

--- Creates a new CL
---
--- @param cl P4_New_CL_Information P4 CL info
--- @return boolean success True if this function is successful.
--- @return P4_CL CL New CL
---
--- @async
--- @nodiscard
function P4_CL:new(cl)
  log.trace("P4_CL (new): Enter")

  local success = true

  local new = setmetatable({}, P4_CL)

  new.change = cl.change
  new.client = cl.client
  new.file_list = cl.file_list

  if success then
    success = new:get_spec()
  end

  log.trace("P4_CL (new): Exit")

  return success, new
end

--- Returns the CL's spec.
---
--- @return string change P4 CL name.
---
--- @async
--- @nodiscard
function P4_CL:get_change()
  log.trace("P4_CL (get_change): Enter")

  self:_check_instance()

  log.trace("P4_CL (get_change): Exit")

  return self.change
end

--- @class P4_CL_Get_Spec_Opts : table
--- @field force boolean Forces a read of the CL spec.
local P4_CL_Get_Spec_Opts = {
  force = false,
}

--- Returns the CL's spec.
---
--- @param opts? P4_CL_Get_Spec_Opts Options.
--- @return boolean success True if this function is successful.
--- @return P4_CL_Spec spec P4 CL spec.
---
--- @async
--- @nodiscard
function P4_CL:get_spec(opts)
  log.trace("P4_CL (get_spec): Enter")

  self:_check_instance()

  opts = vim.tbl_deep_extend("force", P4_CL_Get_Spec_Opts, opts or {})

  local success = true

  if not self.spec or opts.force then

    local P4_Command_Change = require("p4.core.lib.command.change")

    --- @type P4_Command_Change_Options
    local cmd_opts = {
      cl = self.change,
      type = P4_Command_Change.opts_type.READ,
      read = nil,
    }

    local result
    success, result = P4_Command_Change:new(cmd_opts):run()

    if success then

      --- @cast result P4_Command_Change_Result

      -- Build the spec table from the output.
      --FIX: Currently types align, but are different
      self.spec = result
    end
  end

  log.trace("P4_CL (get_spec): Exit")

  return success, self.spec
end

--- Writes the CL spec from a specified buffer to the P4 server.
---
--- @param buf integer Identifies the buffer that will used to store the client spec
---
--- @async
function P4_CL:write_spec(buf)
  log.trace("P4_CL (write_spec): Enter")

  self:_check_instance()

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "p4_spec", { buf = buf })

  vim.api.nvim_buf_set_name(buf, "CL: " .. self.change)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()

      log.trace("P4_CL (write_spec): Callback enter")

      local spec = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      vim.api.nvim_buf_delete(buf, { force = true })

      local P4_Command_Change = require("p4.core.lib.command.change")

      --- @type P4_Command_Change_Options
      local cmd_opts = {
        cl = self.change,
        type = P4_Command_Change.opts_type.WRITE,
        write = {
          input = spec
        },
      }

      local success, _ = P4_Command_Change:new(cmd_opts):run()

      if success then
        notify(("CL %s spec written").format(self.change))

        log.fmt_debug("Successfully written CL's spec: %s", self.change)
      else
        log.fmt_error("Failed to write the CL's spec: %s", self.change)
      end

      log.trace("P4_CL (write_spec): Callback exit")
    end,
  })

  log.trace("P4_CL (write_spec): Exit")
end

--- @class P4_CL_Get_File_List : table
--- @field force boolean Force to read the file list even if it has already been stored.
local P4_CL_Get_File_List = {
  force = false,
}

--- Returns the CL's P4 file list.
---
--- @param opts? P4_CL_Get_File_List Options.
--- @return boolean success True if this function is successful.
--- @return P4_File_List? file_list P4 file list.
---
--- @async
--- @nodiscard
function P4_CL:get_file_list(opts)
  log.trace("P4_CL (get_file_list): Enter")

  self:_check_instance()

  opts = vim.tbl_deep_extend("force", P4_CL_Get_File_List, opts or {})

  local success = self:get_spec()

  if success then
    if not vim.tbl_isempty(self.spec.file_path_list) then

      local P4_File_List = require("p4.core.lib.file_list")

      ---@type P4_File_List_New
      local new_file_list = {
        paths = self.spec.file_path_list,
        convert_depot_paths = false,
        check_in_depot = true,
        get_info = true,
        client = self.client,
        cl = self,
      }

      self.p4_file_list = P4_File_List:new(new_file_list)

      log.fmt_debug("Successfully updated the CL's file list: %s", self.change)
    else
      log.fmt_debug("No files list for CL: %s", self.change)
    end
  end

  log.trace("P4_CL (get_file_list): Exit")

  return success, self.file_list
end

--- Returns the CL's description.
---
--- @return string description.
---
--- @nodiscard
function P4_CL:get_formatted_description()
  log.trace("P4_CL (get_formatted_description): Enter")

  self:_check_instance()

  local description = self.spec.description

  description = description:gsub("\n", " ")
  description = description:gsub("[\t\r]", "")

  log.trace("P4_CL (get_formatted_description): Exit")

  return description
end

return P4_CL
