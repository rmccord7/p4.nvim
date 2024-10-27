local log = require("p4.log")
local shell = require("p4.core.shell")
local env = require("p4.core.env")

local client_cmds = require("p4.core.commands.client")

local client_spec = require("p4.core.parsers.client_spec")

local cl_api = require("p4.api.cl")

--- @class P4_Client
--- @field spec P4_Client_Spec Client spec
--- @field workspace_root_spec string Workspace root file spec
--- @field cl_list P4_CL Pending CL list

local client = {
  cl_list = {},
}

client.__index = client

--- Adds a P4 cl
---
--- @param cl P4_CL P4 cl
local function add_cl(cl)
  log.fmt_info("Add cl: %s", cl.spec.change)

  table.insert(client.cl_list, cl)
end

--- Finds a P4 cl
---
--- @param cl_num string P4 cl name
--- @return P4_CL? cl P4 cl
local function find_cl(cl_num)
  for _, c in ipairs(client.cl_list) do
    if c.spec.cl == cl_num then
      log.fmt_info("Found cl: %s", cl_num)
      return c
    end
  end
  return nil
end

--- Removes a P4 cl
---
--- @param cl_num integer P4 cl
local function remove_cl(cl_num)

  -- TODO: Remove all files

  for i, cl in ipairs(client.cl_list) do
    if cl.spec.cl == cl_num then
      table.remove(client.cl_list, i)
    end
  end
end

--- Cleans up a client's CL's list
local function cleanup_pending_cl_list(self)
  for i, _ in ipairs (self.cl_list) do
    self.cl_list[i] = nil
  end
end

--- Creates a new client
---
--- @param client_name string P4 client name
--- @return P4_Client? client New client
function client.new(client_name)

    -- Make sure the P4 client exists by reading the spec
  local result = shell.run(client_cmds.read_spec(client_name))

  if result.code == 0 then

    local new_client = nil

    new_client = setmetatable({}, client)

    new_client.name = client_name
    new_client.spec = client_spec.parse(result.stdout)

    if vim.tbl_isempty(new_client.spec) then
      log.error("P4 client spec could not be read")
      return nil
    end

    -- Make sure this client belongs to the current user.
    if env.user ~= new_client.spec.owner then
      log.error("P4 client is not owned by the current user")
      return nil
    end

    new_client:get_cl_list()

    new_client.workspace_root_spec = new_client.spec.root .. "/..."

    return new_client
  else
    return nil
  end
end

--- Deletes the specified client
function client.cleanup()
  cleanup_pending_cl_list()
end

--- Edits the client spec
---
--- @param buf integer Identifies the buffer that will used to store the client spec
function client:edit_spec(buf)

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
  vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

  vim.api.nvim_buf_set_name(buf, "Client: " .. self.name)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()
      local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      result = vim.system(client_cmds.write_spec(), { stdin = content }):wait()

      if result.code > 0 then
        log.error(result.stderr)
        return
      end

      vim.api.nvim_buf_delete(buf, { force = true })
    end,
  })
end

--- Get list of CL files
function client:get_cl_list()

  local result
  local cl_num_list = {}

  -- Make sure the client spec has been read
  if self.spec.client then

    -- Delete old files list
    cleanup_pending_cl_list(self)

    result = shell.run(client_cmds.read_cls(self.spec.client))

    if result.code == 0 then

      for index, line in ipairs(vim.split(result.stdout, "\n")) do

        local chunks = {}
        for substring in line:gmatch("%S+") do
          table.insert(chunks, substring)
        end

        -- Second chunk contains the P4 change list number
        table.insert(cl_num_list, index, chunks[2])
      end
    else
      log.error("Cannot read Cls from the P4 client")
    end

    if not vim.tbl_isempty(cl_num_list) then

      self.cl_list = {}

      for _, cl_num in ipairs(cl_num_list) do
        local cl = find_cl(cl_num)

        if cl then

          -- TODO: Set selected CL

        else
          local new_cl = cl_api.new(cl_num)

          if new_cl then
            add_cl(new_cl)
          end
        end
      end
    end
  else
    log.error("Invalid P4 client spec name")
  end
end

--- Removes the specified CL from the P4 client
---
--- @param cl_num integer
function client:remove_cl(cl_num)
  remove_cl(cl_num)
end

return client
