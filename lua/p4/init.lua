local uv = vim.loop
local config = require("p4.config")
local util = require("p4.util")
local p4_commands = require("p4.commands")

local M = {
  p4 = {
      config_path = nil,
      user = os.getenv('P4USER'),
      host = os.getenv('P4HOST'),
      port = os.getenv('P4PORT'),
      client = os.getenv('P4CLIENT'),
  },
}

local function display_workspace_info()
    util.debug("P4USER: " .. M.p4.user['P4USER'])
    util.debug("P4HOST: " .. M.p4.host['P4HOST'])
    util.debug("P4PORT: " .. M.p4.port['P4PORT'])
    util.debug("P4CLIENT: " .. M.p4.client['P4CLIENT'])
end

local function clear_p4_config()
    util.debug("Clearing P4 Config")

    M.p4.config_path = nil
    M.p4.user = nil
    M.p4.host = nil
    M.p4.port = nil
    M.p4.client = nil
end

local function update_p4_config()
    util.debug("Updating P4 Config")

    clear_p4_config()

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
    local path util.find_p4_ancestor(uv.cwd())

    if path then

      M.p4.config_path = util.path.sanitize(path .. "/" .. config.opts.p4.config)

      util.print("Config Path: " .. M.p4.config_path)

      local input = io.open(M.p4.config_path):read("*a")

      if input then

        t = {}
        for k, v in string.gmatch(input, "(%w+)=(%w+)") do
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

local function set_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
end

local function clear_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", true, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })
end

function M.setup(opts)
  if vim.fn.has("nvim-0.7.2") == 0 then
    util.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(opts)
end

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

vim.api.nvim_create_autocmd({"DirChanged"}, {
  pattern = "*",
  callback = function()

    -- Always need to search for new P4 config if directory changed.
    clear_p4_config()

    find_p4_config()
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()

    if find_p4_config() then

      -- Set buffer to reload for changes made outside vim such as pulling latest revisions.
      vim.api.nvim_set_option_value("autoread", false, { scope = "local" })

    end

  end,
})

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

vim.api.nvim_create_autocmd("FileChangedRO", {
  pattern = "*",
  callback = function()
      promot_open_for_edit()
  end,
})

return M
