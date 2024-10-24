local env = require("p4.core.env")
local shell = require("p4.core.shell")
local log = require("p4.core.log")

local client_cmds = require("p4.core.commands.client")

--- @class P4_Client
--- @field name string P4 client name
local client = {
  name = '',
  pending_cl_list = {},
  workspace_root = '',
  workspace_root_spec = '',
}

client.__index = client

--- Cleans up a client's CL's list
local function cleanup_pending_cl_list(self)
  for cl in pairs (self.pending_cl_list) do
    self.pending_cl_list[cl] = nil
  end
end

--- Creates a new client
---
--- @param user? string P4 user
--- @param name? string P4 client
--- @param spec? string P4 client spec if already available
function client:new(user, name, spec)
  user = user or env.user or 'Unknown'
  name = name or env.client or 'Unknown'

  local root = nil

  if not spec then

    -- Make sure the P4 client exists by reading the spec
    local result = shell.run(client_cmds.read_spec(name))

    if result.code == 0 then
      spec = result.stdout
    end
  end

  if spec and string.len(spec) then

    -- Parse the P4 client spec
    for _, line in ipairs(vim.split(spec, "\n")) do

      -- Make sure P4 user matches this client
      if line:find("^User") then

        chunks = {}
        for substring in line:gmatch("%S+") do
          table.insert(chunks, substring)
        end

        -- Make sure this client is for the current user.
        if user ~= chunks[2] then
          log.error("P4 client is not for the current user")
          break
        end
      end

      -- Need to store the workspace root for this client.
      if line:find("^Root") then

        chunks = {}
        for substring in line:gmatch("%S+") do
          table.insert(chunks, substring)
        end

        -- TODO: Handle alt root?

        root = chunks[2]
        break
      end
    end
  end

  local new_client = nil

  if spec and root then

    new_client = {}

    setmetatable(self, new_client)

    new_client.name = name

    new_client.get_cl_list()

    new_client.workspace_root = root
    new_client.workspace_root_spec = root .. "/..."
  end

  return new_client
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
  local cls = {}

  -- Delete old files list
  cleanup_pending_cl_list(self)

  result = shell.run(client_cmds.read_cls(self.name))

  if result.code == 0 then

    for index, line in ipairs(vim.split(result.stdout, "\n")) do

      local chunks = {}
      for substring in line:gmatch("%S+") do
        table.insert(chunks, substring)
      end

      -- Second chunk contains the P4 change list number
      table.insert(cls, index, chunks[2])
    end
  end

  return cls
end

--- Reverts all files for the specified client's pending CL
---
--- @param pending_cl P4_CL
function client:revert_cl_files(pending_cl)
end

--- Shelves all files for the specified client's pending CL
---
--- @param pending_cl P4_CL
function client:shelve_cl_files(pending_cl)
end

--- Deletes  the specified client's pending CL
---
--- @param pending_cl P4_CL
function client:deleted_cl(pending_cl)
end

