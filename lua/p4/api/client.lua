local commands = require("p4.commands")

local core = require("p4.core")
local log = require("p4.core.log")

--- P4 clients.
local M = {}

--- Edits the client spec
function M.edit_spec(client_name, buf)
  client_name = client_name or core.env.client

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
  vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

  vim.api.nvim_buf_set_name(buf, "Client: " .. client_name)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()
      local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      result = vim.system(commands.client.write_spec(client_name), { stdin = content }):wait()

      if result.code > 0 then
        log.error(result.stderr)
        return
      end

      vim.api.nvim_buf_delete(buf, { force = true })
    end,
  })
end

--- Get list of CL files
function M.get_cl_file_list(client_name)
  client_name = client_name or core.env.client

  local result
  local cls = {}

  -- TODO: Check if default change list has files and add it to list

  result = core.shell.run(commands.client.read_change_list_files(client_name))

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

--- Revert CL
function M.revert_cl(client_name, cl)
  client_name = client_name or core.env.client
end

--- Shelve CL
function M.shelve_cl(client_name, cl)
  client_name = client_name or core.env.client
end

--- Delete shelved CL files.
function M.deleted_shelved_cl_files(client_name, cl)
  client_name = client_name or core.env.client
end

--- Delete CL.
function M.deleted_cl(client_name, cl)
  client_name = client_name or core.env.client
end

return M

