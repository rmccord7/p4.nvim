local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Client : table
--- @field protected name string Client name
--- @field protected spec P4_Client_Spec Client spec
--- @field protected root_file_spec File_Spec Workspace root file spec
--- @field protected open_files_list P4_File_List List of open P4 files.
--- @field protected pending_cl_list P4_CL[] List of open P4 CLs.
local P4_Client = {}

P4_Client.__index = P4_Client

--- Wrapper function to check if a table is an instance of this class.
function P4_Client:_check_instance()
  assert(P4_Client.is_instance(self) == true, "Not a P4 CL class instance")
end

--- Returns if the table is an instance of this class.
---
--- @return boolean is_instance True if this is a class instance.
function P4_Client:is_instance()
  local object = self

  while object do
    object = getmetatable(object)

    if object == P4_Client then
      return true
    end
  end

  return false
end

--- @class P4_New_Client_Information
--- @field client_name string P4 client name
--- @field get_pending_cl_list boolean Get the list of CLs that are pending for this client

--- Creates a new client
---
--- @param client_name string P4 client name
--- @return boolean success True if this function is successful.
--- @return P4_Client client New client
---
--- @async
--- @nodiscard
function P4_Client:new(client_name)
  log.trace("P4_Client (new): Enter")

  local new = setmetatable({}, P4_Client)

  new.name = client_name

  log.trace("P4_Client (new): Exit")

  return true, new
end

--- Reads the client spec
---
--- @return string name P4 client name
---
--- @async
--- @nodiscard
function P4_Client:get_name()
  log.trace("P4_File (get_name): Enter")

  self:_check_instance()

  log.trace("P4_File (get_name): Exit")

  return(self.name)
end

--- @class P4_Client_Get_Spec_Opts : table
--- @field force boolean Forces a read of the client spec.
local P4_Client_Get_Spec_Opts = {
  force = false,
}

--- Reads the client spec
---
--- @param opts? P4_Client_Get_Spec_Opts Options.
--- @return boolean success Indicates if the function was successful
--- @return P4_Client_Spec client_spec P4 client spec
---
--- @async
--- @nodiscard
function P4_Client:get_spec(opts)
  log.trace("P4_Client (get_spec): Enter")

  self:_check_instance()

  opts = vim.tbl_deep_extend("force", P4_Client_Get_Spec_Opts, opts or {})

  local success = true

  if not self.spec or opts.force then
    local P4_Command_Client = require("p4.core.lib.command.client")

    --- @type P4_Command_Client_Options
    local cmd_opts = {
      type = P4_Command_Client.opts_type.READ,
    }

    local result
    success, result = P4_Command_Client:new(self.name, cmd_opts):run()

    if success then

      --- @cast result P4_Command_Client_Result

      log.fmt_debug("Successfully read the client's spec: %s", self.name)

      -- Build the spec table from the output.
      self.spec = result

      -- The workspace root may have changed.
      self.root_file_spec = self.spec.root .. "/..."

      log.fmt_info("Client root: %s", self.spec.root);
    else
      log.debug("Failed to read the client's spec: %s", self.name)
    end
  end

  log.trace("P4_Client (get_spec): Exit")

  return success, self.spec
end

--- Writes the client spec from a specified buffer to the P4 server.
---
--- @param buf integer Identifies the buffer that will used to store the client spec
---
--- @async
function P4_Client:write_spec(buf)
  log.trace("P4_Client (write_spec): Enter")

  self:_check_instance()

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "p4_spec", { buf = buf })

  vim.api.nvim_buf_set_name(buf, "Client: " .. self.name)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = require("nio").wrap(function()
      log.trace("P4_Client (write_spec): Callback Enter")

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

      log.trace("P4_Client (write_spec): Callback Exit")
    end, 0),
  })

  log.trace("P4_Client (write_spec): Exit")
end

--- Sends a request to P4 server for a list of the specified client's CLs.
---
--- @return boolean success Indicates if the function was successful.
--- @return P4_CL[] pending_cl_list Pending CL list
---
--- @async
--- @nodiscard
function P4_Client:get_pending_cl_list()
  log.trace("P4_Client (get_pending_cl_list): Enter")

  self:_check_instance()

  -- Read the current client's spec so we can get the client's
  -- workspace root.
  local success = self:get_spec()

  if success then

    local P4_Command_Changes = require("p4.core.lib.command.changes")

    --- @type P4_Command_Changes_Options
    local cmd_opts = {
      client = self.name
    }

    local result_list
    success, result_list = P4_Command_Changes:new(cmd_opts):run()

    if success then

      --- @cast result_list P4_Command_Changes_Result[]

      local P4_CL = require("p4.core.lib.cl")

      self.pending_cl_list = {}

      for _, result in ipairs(result_list) do

        --- @type P4_New_CL_Information
        local new_cl = {
          change = result.name,
          client = self,
        }

        success, p4_cl = P4_CL:new(new_cl)

        if success then
          table.insert(self.pending_cl_list, p4_cl)
        else
          break
        end
      end

      log.fmt_debug("Successfully updated the client's cl list: %s", self.name)
    else
      log.fmt_debug("Failed to read the client's file list: %s", self.name)

      self.pending_cl_list = nil
    end
  end

  log.trace("P4_Client (get_pending_cl_list): Exit")

  return success, self.pending_cl_list
end

--- Sends a request to P4 server for a list of the specified client's open files.
---
--- @return boolean success Indicates if the function was successful.
--- @return P4_File_List p4_file_list List of open P4 files.
---
--- @async
--- @nodiscard
function P4_Client:get_open_files()
  log.trace("P4_Client (get_open_files): Enter")

  self:_check_instance()

  -- Read the current client's spec so we can get the client's
  -- workspace root.
  local success = self:get_spec()

  if success then

    if not self.open_files_list then

      local P4_Command_Opened = require("p4.core.lib.command.opened")

      local results
      success, results = P4_Command_Opened:new():run()

      if success and results then

        assert(#results, "Unepxected number of results")

        local paths = {} ---@type string[]
        local cls = {} ---@type string[]

        for _, result in ipairs(results) do
          if result.success then
            table.insert(paths, result.data.clientFile)
            table.insert(cls, result.data.change)
          else
            -- There will only be one error result if we were unable to get the clients.
            success = false
            break
          end
        end

        if success then

          local P4_File_List = require("p4.core.lib.file_list")

          ---@type P4_File_List_New
          local new_file_list = {
            paths = paths,
            convert_depot_paths = true, -- P4 opened output is depot path.
            check_in_depot = true, -- Files for add may not be in depot so good to have this information
            get_info = true, -- More efficient to do this now
            client = self, -- Should have same client
            cls = cls, -- May have different CLs
          }

          success, self.open_files_list = P4_File_List:new(new_file_list)

          if success then
            log.fmt_debug("Successfully updated the client's file list: %s", self.name)
          end
        end
      end
    end
  end

  log.trace("P4_Client (get_open_files): Exit")

  return success, self.open_files_list
end

--- Adds a P4 CL to the specified P4 client
---
--- @param cl_num integer P4 CL number
--- @return boolean result Returns true if the CL has been added to the client
--- @async
function P4_Client:add_cl(cl_num)
  log.trace("P4_Client (add_cl): Enter")

  self:_check_instance()

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

  log.trace("P4_Client (add_cl): Exit")

  return false
end

--- Removes a P4 cl
---
--- @param cl_num integer P4 CL number
--- @async
function P4_Client:remove_cl(cl_num)
  log.trace("P4_Client (remove_cl): Enter")

  self:_check_instance()
  -- log.tra  for i, cl in ipairs(P4_Client.cl_list) do
  --   if cl.spec.cl == cl_num then
  --     table.remove(self.cl_list, i)
  --   end
  -- end

  log.trace("P4_Client (remove_cl): Exit")
end

return P4_Client
