local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Client : table
--- @field name string Client name
--- @field protected spec P4_Client_Spec Client spec
--- @field protected root_file_spec P4_File_Spec Workspace root file spec
--- @field protected p4_file_list P4_File_List List of open P4 files.
--- @field protected p4_cl_list P4_CL[] List of open P4 CLs.
local P4_Client = {}

--- Creates a new client
---
--- @param client_name string P4 client name
--- @return P4_Client client New client
--- @nodiscard
function P4_Client:new(client_name)

  log.trace("P4_Client: new")

  P4_Client.__index = P4_Client

  local new = setmetatable({}, P4_Client)

  new.name = client_name

  return new
end

--- Reads the client spec
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_Client:read_spec()

  log.trace("P4_Client: read_spec")

  local future = nio.control.future()

  local P4_Command_Client = require("p4.core.lib.command.client")

  --- @type P4_Command_Client_Options
  local cmd_opts = {
    type = P4_Command_Client.opts_type.READ,
  }

  local cmd = P4_Command_Client:new(self.name, cmd_opts)

  local success, sc = pcall(cmd:run().wait)

  if success then

    log.fmt_debug("Successfully read the client's spec: %s", self.name)

    --- @cast sc vim.SystemCompleted

    -- Build the spec table from the output.
    self.spec = cmd:process_response(sc.stdout)

    -- The workspace root may have changed.
    self.root_file_spec = self.spec.root .. "/..."

    log.fmt_info("Client root: %s", self.spec.root);

    future.set()
  else
    log.debug("Failed to read the client's spec: %s", self.name)

    future.set_error()
  end

  return future
end

--- Writes the client spec from a specified buffer to the P4 server.
---
--- @param buf integer Identifies the buffer that will used to store the client spec
function P4_Client:write_spec(buf)

  log.trace("P4_Client: write_spec")

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
  vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

  vim.api.nvim_buf_set_name(buf, "Client: " .. self.name)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = nio.wrap(function()
      local spec = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      vim.api.nvim_buf_delete(buf, { force = true })

      local P4_Command_Client = require("p4.core.lib.command.client")

      local cmd = P4_Command_Client:client()

      cmd.sys_opts["stdin"] = spec

      local success, _ = pcall(cmd:run().wait)

      if success then
        notify(("Client %s spec written").format(self.name))
        log.fmt_debug("Successfully written client's spec: %s", self.name)
      else
        log.fmt_debug("Failed to write the client's spec: %s", self.name)
      end
    end, 0),
  })
end

--- Sends a request to P4 server for a list of the specified client's CLs.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_Client:update_cl_list()

  log.trace("P4_Client: update_cl_list")

  local future = nio.control.future()

  -- Read the current client's spec so we can get the client's
  -- workspace root.
  local success, _ = pcall(self:read_spec().wait)

    if success then

      local P4_Command_Changes = require("p4.core.lib.command.changes")

      --- @type P4_Command_Changes_Options
      local cmd_opts = {
        client = self.name
      }

      local cmd = P4_Command_Changes:new(cmd_opts)

      local sc

      success, sc = pcall(cmd:run().wait)

      if success then

        --- @cast sc vim.SystemCompleted

        --- @type P4_Command_Changes_Result[]
        local result_list = cmd:process_response(sc.stdout)

        local P4_CL = require("p4.core.lib.cl")

        self.p4_cl_list = {}

        for _, result in ipairs(result_list) do

          --- @type P4_New_CL_Information
          local new_cl = {
            name = result.name,
            client = self,
            user = result.user,
            description = result.description,
            status = P4_CL.set_status_from_string(result.status),
          }

          local p4_cl = P4_CL:new(new_cl)

          table.insert(self.p4_cl_list, p4_cl)
        end

        log.fmt_debug("Successfully updated the client's cl list: %s", self.name)

        future.set()
      else
        log.fmt_debug("Failed to read the client's file list: %s", self.name)

        self.p4_cl_list = nil

        future.set_error()
      end
    else
      log.error("Failed to read the client's spec: %s", self.name)
    end

  return future
end

--- Returns the list of P4 files that are open for the specified client.
---
--- @return P4_CL[] p4_cl_list List of P4 CLs.
--- @nodiscard
function P4_Client:get_cl_list()
  log.trace("P4_Client: get_cl_list")

  return self.p4_cl_list
end

--- Sends a request to P4 server for a list of the specified client's open files.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
function P4_Client:update_file_list()

  log.trace("P4_Client: update_file_list")

  local future = nio.control.future()

  -- Read the current client's spec so we can get the client's
  -- workspace root.
  local success, _ = pcall(self:read_spec().wait)

  if success then
    local P4_Command_Opened = require("p4.core.lib.command.opened")

    local sc
    local cmd = P4_Command_Opened:new()

    success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then

      --- @type P4_Command_Opened_Result[]
      local result = cmd:process_response(sc.stdout)

      if #result > 0 then

        local P4_File_Path = require("p4.core.lib.file_path")
        local P4_File_List = require("p4.core.lib.file_list")
        local P4_CL = require("p4.core.lib.cl")

        --- @type P4_New_File_Information[]
        local new_file_list = {}

        for _, file_info in ipairs(result) do

          --- @type P4_New_CL_Information
          local new_cl = {
            name = file_info.cl,
            client = self,
          }

          --- @type P4_New_File_Information
          local new_file = {
            client = self,
            cl = P4_CL:new(new_cl),
            path = {
              type = P4_File_Path.type.DEPOT,
              path = file_info.path,
            },
          }

          table.insert(new_file_list, new_file)
        end

        self.p4_file_list = P4_File_List:new(new_file_list)

        log.fmt_debug("Successfully updated the client's file list: %s", self.name)

        success, _ = pcall(self.p4_file_list:update_stats().wait)

        if success then
          future.set()
        else
          future.set_error()
        end
      else
        future.set()
      end
    end
  else
    log.fmt_debug("Failed to read the client's file list: %s", self.name)

    self.p4_file_list = nil

    future.set_error()
  end

  return future
end

--- Returns the list of P4 files that are open for the specified client.
---
--- @return P4_File_List p4_file_list List of open P4 files.
--- @nodiscard
function P4_Client:get_file_list()
  log.trace("P4_Client: get_file_list")

  return self.p4_file_list
end

--- Adds a P4 CL to the specified P4 client
---
--- @param cl_num integer P4 CL number
--- @return boolean result Returns true if the CL has been added to the client
--- @async
function P4_Client:add_cl(cl_num)

  log.trace("P4_Client: add_cl")

  -- if not self:find_cl(cl_num) then
  --
  --   cl = P4_CL:new(cl_num)
  --
  --   if cl then
  --
  --     log.fmt_info("Add CL: %s", cl.num)
  --
  --     table.insert(self.cl_list, cl)
  --
  --     return true
  --   end
  -- end

  return false
end

--- Finds a P4 CL in the specified P4 client
---
--- @param cl_num integer P4 CL number
--- @return P4_CL? cl P4 CL
--- @async
function P4_Client:find_cl(cl_num)

  log.trace("P4_Client: find_cl")

  -- for _, c in ipairs(self.cl_list) do
  --   if c.num == cl_num then
  --     log.fmt_info("Found CL: %s", cl_num)
  --     return c
  --   end
  -- end

  return nil
end

--- Removes a P4 cl
---
--- @param cl_num integer P4 CL number
--- @async
function P4_Client:remove_cl(cl_num)

  log.trace("P4_Client: remove_cl")

  -- log.tra  for i, cl in ipairs(P4_Client.cl_list) do
  --   if cl.spec.cl == cl_num then
  --     table.remove(self.cl_list, i)
  --   end
  -- end
end

return P4_Client
