local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_CL : table
--- @field name string P4 CL name
--- @field user string CL user.
--- @field client_name string CL Client's name.
--- @field description string CL description.
--- @field status P4_CL_STATUS_TYPE CL status.
--- @field protected spec P4_CL_Spec CL spec
--- @field protected p4_file_list P4_File_List List of P4 files that are open for the CL.
local P4_CL = {}

--- Creates a new CL
---
--- @param cl P4_CL_Information P4 CL info
--- @return P4_CL CL New CL
--- @nodiscard
function P4_CL:new(cl)

  P4_CL.__index = P4_CL

  local new = setmetatable({}, P4_CL)

  new.name = cl.name
  new.user = cl.user
  new.client_name = cl.client_name
  new.description = cl.description
  new.status = cl.status

  return new
end

--- Returns the CLs P4 file list.
---
--- @return P4_File_List result P4 file list.
function P4_CL:get_file_list()
  return self.p4_file_list
end

--- Returns the CLs description.
---
--- @return string description.
function P4_CL:get_formatted_description()
  local description = self.description

  description = description:gsub("\n", " ")
  description = description:gsub("[\t\r]", "")

  return description
end

--- Reads the client spec from the P4 server.
---
--- @param on_exit fun(success: boolean, ...) Callback function when function completes
function P4_CL:read_spec(on_exit)

  log.fmt_debug("Reading the CL's spec: %s", self.name)

  nio.run(function()

    local P4_Command_Change = require("p4.core.lib.command.change")

    --- @type P4_Command_Change_Options
    local cmd_opts = {
      read = true,
    }

    local cmd = P4_Command_Change:new(self.name, cmd_opts)

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      log.fmt_debug("Successfully read the CL's spec: %s", self.name)

      -- Build the spec table from the output.
      self.spec = cmd:process_response(sc.stdout)

    else
      log.error("Failed to read the CL's spec: %s", self.name)
    end

    on_exit(success)
  end)
end

--- Writes the CL spec from a specified buffer to the P4 server.
---
--- @param buf integer Identifies the buffer that will used to store the client spec
function P4_CL:write_spec(buf)

  log.fmt_debug("Write CL's spec: %s", self.name)

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
  vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

  vim.api.nvim_buf_set_name(buf, "CL: " .. self.name)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()

      spec = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      vim.api.nvim_buf_delete(buf, { force = true })

      nio.run(function()

        local P4_Command_Change = require("p4.core.lib.command.change")

        local cmd = P4_Command_Change:new(self.name)

        cmd.sys_opts["stdin"] = spec

        success, sc = pcall(cmd:run().wait)

        --- @cast sc vim.SystemCompleted

        if success then
          notify(("CL %s spec written").format(self.name))
          log.fmt_debug("Successfully written CL's spec: %s", self.name)
        else
          log.fmt_error("Failed to write the CL's spec: %s", self.name)
        end
      end)
    end,
  })
end

--- Gets files from the CL spec
---
--- @param on_exit fun(success: boolean, ...) Callback function when function completes
function P4_CL:update_file_list_from_spec(on_exit)

  log.fmt_debug("Get files from CL spec: %s", self.name)

  nio.run(function()

    -- Update the CL spec in case the file list has recently changed.
    self:read_spec(function(success)

      if success then

        if not vim.tbl_isempty(self.spec.files) then

          local file_utils = require("p4.core.lib.file_utils")

          --- @type New_P4_File[]
          local new_file_list = {}
          for _, file_path in ipairs(self.spec.files) do

            --- @type New_P4_File
            local new_file = {
              file_path_type = P4_FILE_PATH_TYPE.depot,
              file_path = file_path,
              p4_cl = self
            }

            table.insert(new_file_list, new_file)
          end

          local P4_File_List = require("p4.core.lib.file_list")
          self.p4_file_list = P4_File_List:new(new_file_list, self)

          log.fmt_debug("Successfully updated the CL's file list: %s", self.name)

          --- @diagnostic disable-next-line Ignore redefined success.
          self.p4_file_list:update_stats(function(success)
            on_exit(success)
          end)
        else
          log.fmt_debug("No files list for CL: %s", self.name)

          on_exit(false)
        end
      else
        on_exit(false)
      end
    end)
  end)
end

return P4_CL
