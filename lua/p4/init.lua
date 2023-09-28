local config = require("p4.config")
local util = require("p4.util")
local p4_commands = require("p4.commands")

local function p4_config_exists()

  -- For now just check if this is in our cwd.
  if vim.loop.fs_stat(config.opts.p4.config) then

    util.debug("Found P4config")
    return true
  else
    util.debug("No P4config found")
    return false
  end
end

local function prompt_open_for_add()

    vim.fn.inputsave()
    local result = vim.fn.input("Open for add (y/n): ")
    vim.fn.inputrestore()

    if result == "y" or result == "Y" then
      require("p4").add()
    end
end

local function promot_open_for_edit()

    vim.fn.inputsave()
    local result = vim.fn.input("Open for edit (y/n): ")
    vim.fn.inputrestore()

    if result == "y" or result == "Y" then
      require("p4").edit()
    end
end

local function set_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
end

local function clear_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", true, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })
end

local M = {}

function M.setup(opts)
  if vim.fn.has("nvim-0.7.2") == 0 then
    util.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(opts)
end

function M.add(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = util.run_command(p4_commands.add_file(file_path))

  if result.code == 0 then
    util.print("Opened for add")

    set_buffer_writeable()
  end
end

function M.edit(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = util.run_command(p4_commands.edit_file(file_path))

  if result.code == 0 then
    set_buffer_writeable()

    util.print("Opened for edit")
  end
end

function M.revert(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = util.run_command(p4_commands.revert_file(file_path))

  if result.code == 0 then
    clear_buffer_writeable()

    util.print("Reverted file")
  end
end

--vim.api.nvim_create_autocmd("BufNew", {
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

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()

    if p4_config_exists() then

      -- Set buffer to reload for changes made outside vim such as pulling latest revisions.
      vim.api.nvim_set_option_value("autoread", false, { scope = "local" })

    end

  end,
})

vim.api.nvim_create_autocmd("BufWrite", {
  pattern = "*",
  callback = function()
    if p4_config_exists() then
      local file_path = vim.fn.expand("%:p")
      local modifiable = vim.api.nvim_buf_get_option(0, "modifiable")

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

vim.api.nvim_create_autocmd("FileChangedRO", {
  pattern = "*",
  callback = function()
    if p4_config_exists() then

      promot_open_for_edit()
    end
  end,
})

return M
