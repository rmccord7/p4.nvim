local log = require("p4.log")
local notify = require("p4.notify")

local config = require("p4.config")

---@class P4_Env : table
---@field user? string Identifies the P4 user
---@field host? string Identifies the P4 host
---@field port? string Identifies the P4 port
---@field client? string Identifies the P4 client
local P4_Env = {
  user = nil,
  host = nil,
  port = nil,
  client = nil,
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

--- Tries to update the P4 environment information from NVIM variables.
local function update_env_from_NVIM()
  log.trace("Trying to update P4 environment from NVIM")

  if vim.g.p4 and vim.g.p4.config then
    P4_Env.user = vim.g.p4.config.user
    P4_Env.host = vim.g.p4.config.host
    P4_Env.port = vim.g.p4.config.port
    P4_Env.client = vim.g.p4.config.client
  end

  -- Everything must be configured from one place.
  if check_env() then
    log.info("P4 environment configured from NVIM")
  else
    P4_Env.clear()
  end
end

--- Tries to update the P4 environment innformation from the shell's
--- environment.
local function update_env_from_shell()
  log.trace("Trying to update P4 environment from the shell enviroment")

  P4_Env.user = os.getenv("P4USER")
  P4_Env.host = os.getenv("P4HOST")
  P4_Env.port = os.getenv("P4PORT")
  P4_Env.client = os.getenv("P4CLIENT")

  -- Everything must be configured from one place.
  if check_env() then
    log.info("P4 environment configured from the shell enviroment")
  else
    P4_Env.clear()
  end
end

--- Tries to update the P4 environment information from a P4CONFIG file.
local function update_env_from_config_file()
  log.trace("Trying to update P4 environment from the shell enviroment")

  log.debug("Looking for P4CONFIG: " .. config.opts.p4.config)

  local config_path = vim.fs.find(config.opts.p4.config, {
    upward = true,
  })[1]

  if config_path then
    log.debug("P4CONFIG Path: " .. config_path)

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

      -- Everything must be configured from one place.
      if check_env() then
        log.info("P4 environment configured from config file")
      else
        P4_Env.clear()
      end
    end
  else
    log.debug("P4 Config: Not found")
  end
end

--- Clears the P4 environment information
function P4_Env.clear()
  log.debug("Clearing P4 config")

  P4_Env.user = nil
  P4_Env.host = nil
  P4_Env.port = nil
  P4_Env.client = nil
end

--- Gets the P4 environment information is valid.
---
--- @return P4_Env? P4_Env P4 environment if valid. Otherwise nil.
--- @nodiscard
function P4_Env.get()
  log.trace("Get P4 Enviroment")

  local env_valid = check_env()

  if env_valid then
    return P4_Env
  else
    return nil
  end
end

--- Updates the P4 environment information
function P4_Env.update()
  log.trace("Updating P4 environment")

  -- If we have already cached the P4 environment
  -- information, then there is nothing to do.
  if not check_env() then

    -- Plugin config for P4 config has highest precedence
    update_env_from_NVIM()

    -- P4CONFIG for P4 config has the next highest precendence
    if not check_env() then

      update_env_from_config_file()
    end

    -- Enviroment for P4 config has next highest precedence
    if not check_env() then
      -- Try to get P4 information from the shell enviroment
      -- (user using something like direnv).
      update_env_from_shell()
    end

    local ac = require("p4.core.ac")

    -- Handle invalid configuration
    if check_env() then
      display_env()

      log.debug("P4 environment configured")

      -- Enable autocmds
      ac.enable_autocmds()
    else
      -- Disable autocmds
      ac.disable_autocmds()

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

      log.error("Configuring P4 environment failed")
    end

    vim.api.nvim_exec_autocmds('User', {
      pattern = 'P4EnvUpdate',
    })
  end

  return check_env()
end

--- Checks if the P4 environment information is valid.
function P4_Env.check()
  log.trace("Checking P4 environment")

  local env_valid = check_env()

  if not env_valid then
    log.debug("P4 environment not configured")
  end

  return env_valid
end

return P4_Env
