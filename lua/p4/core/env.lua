local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

local config = require("p4.core.config")

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

    t = {}
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
      require("p4.api.file.auto").enable_autocmds()

      local P4_Current_Client = require("p4.core.lib.current_client")

      -- Update the current client.
      if not p4.current_client or p4.current_client.name ~= P4_Env.client then
        p4.current_client = P4_Current_Client:new(P4_Env.client)
      end
    else

      -- Disable autocmds
      require("p4.api.file.auto").disable_autocmds()

      -- Update the current client.
      if not p4.current_client or p4.current_client.name ~= P4_Env.client then
        p4.current_client = nil
      end

      -- If nothing is configured, then we will assume this is
      -- not a P4 workspace.
      if P4_Env.user or P4_Env.host or P4_Env.port or P4_Env.cient then

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

  return P4_Env.valid
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

