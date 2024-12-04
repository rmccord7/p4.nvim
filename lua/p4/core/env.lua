local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")
local task = require("p4.task")

local config = require("p4.core.config")

---@class P4_Env : table
---@field user? string Identifies the P4 user
---@field host? string Identifies the P4 host
---@field port? string Identifies the P4 port
---@field client? string Identifies the P4 client
---@field private ac_group? integer Identifies the P4 client
local P4_Env = {
  user = nil,
  host = nil,
  port = nil,
  client = nil,
  ac_group = nil,
}

--- Checks to make sure the P4 enviroment is configured.
local function check_env()
  if P4_Env.user and P4_Env.host and P4_Env.port and P4_Env.client then
    return true
  else
    return false
  end
end

--- Displays P4 environment information.
local function display_env()
  log.info("P4USER: " .. P4_Env.user)
  log.info("P4HOST: " .. P4_Env.host)
  log.info("P4PORT: " .. P4_Env.port)
  log.info("P4CLIENT: " .. P4_Env.client)
end

--- Updates the P4 environment innformation from the shell's
--- environment.
local function update_from_config()
  if vim.g.p4 and vim.g.p4.config then
    P4_Env.user = vim.g.p4.config.user
    P4_Env.host = vim.g.p4.config.host
    P4_Env.port = vim.g.p4.config.port
    P4_Env.client = vim.g.p4.config.client
  end

  if check_env() then
    log.info("P4 configured from plugin config")
  end
end

--- Updates the P4 environment innformation from the shell's
--- environment.
local function update_from_env()
  P4_Env.user = os.getenv('P4USER')
  P4_Env.host = os.getenv('P4HOST')
  P4_Env.port = os.getenv('P4PORT')
  P4_Env.client = os.getenv('P4CLIENT')

  if check_env() then
    log.info("P4 configured from enviroment")
  end
end

--- Updates the P4 environment innformation from a P4CONFIG file.
local function update_from_file(config_path)

  local input = io.open(config_path):read("*a")

  if input then

    local t = {}
    for k, v in string.gmatch(input, "([%w._]+)=([%w._]+)") do
      t[k] = v
    end

    P4_Env.user = t["P4USER"]
    P4_Env.host = t["P4HOST"]
    P4_Env.port = t["P4PORT"]
    P4_Env.client = t["P4CLIENT"]

    if check_env() then
      log.info("P4 configured from P4CONFIG")
    end
  end
end

--- Prompts the user to open the file for add.
local function prompt_open_for_add(file_path)

    if P4_Env.check() then

      vim.fn.inputsave()
      local result = vim.fn.input("Open for add (y/n): ")
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        local P4_File_API = require("p4.api.file")

        P4_File_API.add(file_path)
      end
    end
end

--- Prompts the user to open the file for edit.
local function prompt_open_for_edit(file_path)

    if P4_Env.check() then

      -- Prevent changing read only warning
      vim.api.nvim_set_option_value("readonly", false, { scope = "local" })

      vim.fn.inputsave()
      local opts = {prompt = '[P4] Open file for edit (y/n): ' }
      local _, result = pcall(vim.fn.input, opts)
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        local P4_File_API = require("p4.api.file")

        P4_File_API.edit({file_path})
      else
        vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })

        -- Exit insert mode
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), 'm', false)
      end
    end
end

--- Enables autocmds
---
local function enable_autocmds()

  P4_Env.ac_group = vim.api.nvim_create_augroup("P4_File", {})

  --- Check for P4 workspace when buffer is entered.
  ---
  vim.api.nvim_create_autocmd("BufEnter", {
    group = P4_Env.ac_group,
    pattern = "*",
    callback = function()

      if P4_Env.update() then

        -- Set buffer to reload for changes made outside vim such as
        -- pulling latest revisions.
        vim.api.nvim_set_option_value("autoread", false, { scope = "local" })

      end
    end,
  })

  vim.api.nvim_create_autocmd("BufNewFile", {
    group = P4_Env.ac_group,
    pattern = "*",
    callback = function()
      prompt_open_for_add(vim.fn.expand("%:p"))
    end,
  })

  --- If the buffer is written, then prompt the user whether they want
  --- the associated file opened for add/edit in the client workspace.
  ---
  vim.api.nvim_create_autocmd("BufWrite", {
    group = P4_Env.ac_group,
    pattern = "*",
    callback = function()
      if P4_Env.update() then
        local file_path = vim.fn.expand("%:p")
        local modifiable = vim.api.nvim_get_option_value("modifiable", { scope = "local" })

        if not modifiable then

          if vim.fn.filereadable(file_path) then

            prompt_open_for_edit(file_path)

          else
            prompt_open_for_add(file_path)
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
    group = P4_Env.ac_group,
    pattern = "*",
    callback = function()
        prompt_open_for_edit(vim.fn.expand("%:p"))
    end,
  })
end

--- Disables autocmds
---
local function disable_autocmds()

  if P4_Env.ac_group then

     -- Remove file autocmds
    vim.api.nvim_del_augroup_by_id(P4_Env.ac_group)

    P4_Env.ac_group = nil
  end
end

--- Clears the P4 environment information
function P4_Env.clear()

  log.debug("Clearing P4 config")

  -- NOTE: This does not clear the P4CONFIG path if it has been cached.

  P4_Env.user = nil
  P4_Env.host = nil
  P4_Env.port = nil
  P4_Env.client = nil
end

--- Updates the P4 environment information
function P4_Env.update()

  log.debug("Updating P4 config")

  -- If we have already cached the P4 environment
  -- information, then there is nothing to do.
  if not check_env() then

    log.info("Configuring P4")

    -- Clear the current p4 environment information
    P4_Env.clear()

    -- Plugin config for P4 config has highest precedence
    update_from_config()

    -- P4CONFIG for P4 config has the next highest precendence
    if not check_env() then

      -- Find P4 config file so we can try to use it.
      if config.find() then

        -- Need to find the P4CONFIG file to load p4 environment
        -- information.
        if config.config_path then

          update_from_file(config.config_path)
        end
      end
    end

    -- Enviroment for P4 config has next highest precedence
    if not check_env() then

      -- Try to get P4 information from the shell enviroment
      -- (user using something like direnv).
      update_from_env()

    end

    local p4 = require("p4")

    -- Handle invalid configuration
    if check_env() then

      display_env()

      log.debug("P4 configured")

      -- Enable autocmds
      enable_autocmds()

      local P4_Current_Client = require("p4.core.lib.current_client")

      -- Update the current client.
      if not p4.current_client or p4.current_client.name ~= P4_Env.client then
        p4.current_client = P4_Current_Client:new(P4_Env.client)

        nio.run(function()
          p4.current_client:read_spec(function()
          end)
        end, function(success, ...)
          task.complete(nil, success, ...)
        end)
      end
    else

      -- Disable autocmds
      disable_autocmds()

      -- Update the current client.
      if not p4.current_client or p4.current_client.name ~= P4_Env.client then
        p4.current_client = nil
      end

      -- If nothing is configured, then we will assume this is
      -- not a P4 workspace.
      if P4_Env.user or P4_Env.host or P4_Env.port or P4_Env.client then

        -- Inform the user what has not been set.
        if not P4_Env.host then
          notify("Invalid P4Host", vim.log.levels.ERROR)

          log.error("Invalid P4HOST")
        else
          if not P4_Env.port then
            notify("Invalid P4PORT", vim.log.levels.ERROR)

            log.error("Invalid P4PORT")
          else
            if not P4_Env.client then
              notify("Invalid P4CLIENT", vim.log.levels.ERROR)

              log.error("Invalid P4CLIENT")
            else
              if not P4_Env.user then
                notify("Invalid P4USER", vim.log.levels.ERROR)

                log.error("Invalid P4USER")
              end
            end
          end
        end
      end

      log.error("Configuring P4 failed")

      -- Clear the current p4 environment information
      P4_Env.clear()

    end
  end

  return check_env()
end

--- Clears the P4 environment information
function P4_Env.check()

  if check_env() then
    return true
  else
    notify("Env not configured", vim.log.levels.ERROR)

    log.debug("Env not configured")

    return false
  end
end

return P4_Env

