local uv = vim.loop
local config = require("p4.config")
local util = require("p4.util")
local p4_commands = require("p4.commands")

--- P4 config.
local M = {
  p4 = { -- perforce config
      config_path = nil,-- path to config file
      user = os.getenv('P4USER'), -- identifies the P4 user
      host = os.getenv('P4HOST'), -- identifies the P4 host
      port = os.getenv('P4PORT'), -- identifies the P4 port
      client = os.getenv('P4CLIENT'), -- identifies the P4 client
  },
}

--- Displays P4 environment information.
local function display_workspace_info()
    util.debug("P4USER: " .. M.p4.user)
    util.debug("P4HOST: " .. M.p4.host)
    util.debug("P4PORT: " .. M.p4.port)
    util.debug("P4CLIENT: " .. M.p4.client)
end

--- Clears the P4 environment information.
local function clear_p4_config()
    util.debug("Clearing P4 Config")

    M.p4.config_path = nil
    M.p4.user = nil
    M.p4.host = nil
    M.p4.port = nil
    M.p4.client = nil
end

--- Updates the P4 environment information.
local function update_p4_config()
    util.debug("Updating P4 Config")

    clear_p4_config()

    util.debug("P4CONFIG: " .. config.opts.p4.config)

    -- Try to get the workspace information from environment (direnv, etc)
    M.p4.user = os.getenv('P4USER')
    M.p4.host = os.getenv('P4HOST')
    M.p4.port = os.getenv('P4PORT')
    M.p4.client = os.getenv('P4CLIENT')

    if M.p4.user and M.p4.host and M.p4.port and M.p4.client then

       util.debug("Found environment config")
       return
    end

    -- Find the P4 config at workspace root to get workspace information.
    local path = util.find_p4_ancestor(uv.cwd())

    if path then

      M.p4.config_path = util.path.sanitize(path .. "/" .. config.opts.p4.config)

      util.print("Config Path: " .. M.p4.config_path)

      local input = io.open(M.p4.config_path):read("*a")

      if input then

        t = {}
        for k, v in string.gmatch(input, "([%w._]+)=([%w._]+)") do
          t[k] = v
        end

        M.p4.user = t["P4USER"]
        M.p4.host = t["P4HOST"]
        M.p4.port = t["P4PORT"]
        M.p4.client = t["P4CLIENT"]

        if M.p4.user and M.p4.host and M.p4.port and M.p4.client then

          display_workspace_info()
          return
        else
          clear_p4_config()
          util.debug("Config: Invalid configuration")
        end

      end

    else
      util.debug("Config: Not found")
    end
end

--- Finds the P4 config file.
local function find_p4_config()
  util.debug("Finding P4 Config")

  if M.p4.config_path == nil then

    update_p4_config()

    if M.p4.user and M.p4.host and M.p4.port and M.p4.client then
      return true
    else
      return false
    end
  else
    util.debug("P4 Config: " .. M.p4.config_path)
    return true
  end
end

--- Prompts the user to open the file for add.
local function prompt_open_for_add()

    if find_p4_config() then

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

    if find_p4_config() then

      vim.fn.inputsave()
      local result = vim.fn.input("Open for edit (y/n): ")
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        M.edit()
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

--- Initializes the plugin.
---
--- @param opts table? P4 options
function M.setup(opts)
  if vim.fn.has("nvim-0.7.2") == 0 then
    util.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(opts)
end

--- Verifies that the current workspace has a valid P4 config file.
---
--- @return boolean config_found # Indicates if a valid p4 config has been found.
---
function M.verify_workspace()

  local config_found = find_p4_config()

  if not config_found then

    if not M.p4.client then
      util.error("Invalid client")
    else
      if not M.p4.port then
        util.error("Invalid port")
      else
        if not M.p4.host then
          util.error("Invalid host")
        else
          if not M.p4.user then
            util.error("Invalid user")
          end
        end
      end
    end
  end

  return(config_found)
end

--- Opens a file in the client workspace for addition to the P4 depot.
---
--- @param opts table? Optional parameters. Not used.
---
function M.add(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = util.run_command(p4_commands.add_file(file_path))

  if result.code == 0 then
    util.print("Opened for add")

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

  local result = util.run_command(p4_commands.edit_file(file_path))

  if result.code == 0 then
    set_buffer_writeable()

    util.print("Opened for edit")
  end
end

--- Reverts a file in the client workspace.
---
--- @param opts table? Optional parameters. Not used.
---
function M.revert(opts)
  opts = opts or {}

  local file_path = vim.fn.expand("%:p")

  local result = util.run_command(p4_commands.revert_file(file_path))

  if result.code == 0 then
    clear_buffer_writeable()

    util.print("Reverted file")
  end
end

--- Test function.
---
--- @param opts table? Optional parameters. Not used.
---
function M.test(opts)
  opts = opts or {}

  util.print(uv.cwd())

  local path = util.find_p4_ancestor(uv.cwd())

  if path then
    util.print(path)
  else
    util.print("Not found")
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

--- Update the P4 config file if the current working directory
--- changes since we may have changed workspaces.
---
vim.api.nvim_create_autocmd({"DirChanged"}, {
  pattern = "*",
  callback = function()

    -- Always need to search for new P4 config if directory changed.
    clear_p4_config()

    find_p4_config()
  end,
})

--- Reload buffer if the file changes outside neovim.
---
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()

    if find_p4_config() then

      -- Set buffer to reload for changes made outside vim such as
      -- pulling latest revisions.
      vim.api.nvim_set_option_value("autoread", false, { scope = "local" })

    end

  end,
})

--- If the buffer is written, then prompt the user whether they want
--- the associated file opened for add/edit in the client workspace.
---
vim.api.nvim_create_autocmd("BufWrite", {
  pattern = "*",
  callback = function()
    if find_p4_config() then
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
  pattern = "*",
  callback = function()
      promot_open_for_edit()
  end,
})

return M
