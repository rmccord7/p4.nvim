local p4_commands = require("p4.commands")
local p4_util = require("p4.util")

local p4c_env = require("p4.core.env")

--- P4 file
local M = {
  ac_group = nil, -- autocmd group ID
}

--- Prompts the user to open the file for add.
local function prompt_open_for_add()

    -- Ensure P4 environment information is valid
    if p4c_env.update() then

      vim.fn.inputsave()
      local result = vim.fn.input("Open for add (y/n): ")
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        M.add()
      end
    end
end

--- Prompts the user to open the file for edit.
local function promot_open_for_edit()

    -- Ensure P4 environment information is valid
    if p4c_env.update() then

      -- Prevent changing read only warning
      vim.api.nvim_set_option_value("readonly", false, { scope = "local" })

      vim.fn.inputsave()
      local opts = {prompt = '[P4] Open file for edit (y/n): ' }
      local _, result = pcall(vim.fn.input, opts)
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        M.edit()
      else
        vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })

        -- Exit insert mode
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), 'm', false)
      end
    end
end

--- Makes the current buffer writeable.
local function set_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
end

--- Makes the current buffer read only.
local function clear_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", true, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })
end

--- Opens a file in the client workspace for addition to the P4 depot.
---
--- @param opts table? Optional parameters. Not used.
---
function M.add(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = p4_util.run_command(p4_commands.add_file(file_path))

  if result.code == 0 then
    p4_util.print("Opened for add")

    set_buffer_writeable()
  end
end

--- Checks out a file in the client workspace for changes to the P4 depot.
---
--- @param opts table? Optional parameters. Not used.
---
function M.edit(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = p4_util.run_command(p4_commands.edit_file(file_path))

  if result.code == 0 then
    set_buffer_writeable()

    p4_util.print("Opened for edit")
  end
end

--- Reverts a file in the client workspace.
---
--- @param opts table? Optional parameters. Not used.
---
function M.revert(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = p4_util.run_command(p4_commands.revert_file(file_path))

  if result.code == 0 then
    clear_buffer_writeable()

    p4_util.print("Reverted file")
  end
end

--- Enables autocmds
---
function M.enable_autocmds()

  M.ac_group = vim.api.nvim_create_augroup("P4_File", {})

  --vim.api.nvim_create_autocmd("BufNew", {
  --  group = group_id,
  --  pattern = "*",
  --  callback = function()
  --    vim.fn.inputsave()
  --    local result = vim.fn.input("Open for add (y/n): ")
  --    vim.fn.inputrestore()
  --
  --    if result == "y" or result == "Y" then
  --      require("p4").add()
  --    end
  --  end,
  --})

  --- If the buffer is written, then prompt the user whether they want
  --- the associated file opened for add/edit in the client workspace.
  ---
  vim.api.nvim_create_autocmd("BufWrite", {
    group = M.ac_group,
    pattern = "*",
    callback = function()
      if p4c_env.update() then
        local file_path = vim.fn.expand("%:p")
        local modifiable = vim.api.nvim_get_option_value("modifiable", { scope = "local" })

        if not modifiable then

          if vim.fn.filereadable(file_path) then

            promot_open_for_edit()

          else
            prompt_open_for_add()
          end
        end
      end
    end,
  })

  --- If the buffer is modified and read only, then prompt the user
  --- whether they want the associated file opened for edit in the
  --- client workspace.
  ---
  vim.api.nvim_create_autocmd("FileChangedRO", {
    group = M.ac_group,
    pattern = "*",
    callback = function()
        promot_open_for_edit()
    end,
  })
end

--- Disables autocmds
---
function M.disable_autocmds()

  if M.ac_group then

     -- Remove file autocmds
    vim.api.nvim_del_augroup_by_id(M.ac_group)

    M.ac_group = nil
  end
end

return M

