local commands = require("p4.commands")

local core = require("p4.core")
local log = require("p4.core.log")

--- @class P4_Client
--- @field name string P4 client name
--- @field pending_cl_list P4_CL[] List of pending CLs
local client = {
  name = '',
  pending_cl_list = {},
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
--- @param name? string P4 client name
function client:new(name)
  name = name or core.env.client

  local new_client = {}

  setmetatable(self, new_client)

  new_client.name = name

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

      result = vim.system(commands.client.write_spec(), { stdin = content }):wait()

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

  result = core.shell.run(commands.client.read_cls(self.name))

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

return M

