local log = require("p4.log")

local config = require("p4.core.config")

--- P4 env
local M = {
    valid = false, -- indicates if p4 enviroment information is valid
    user = nil, -- identifies the P4 user
    host = nil, -- identifies the P4 host
    port = nil, -- identifies the P4 port
    client = nil, -- identifies the P4 client
}

--- Displays P4 environment information.
local function display_env()
    log.info("P4USER: " .. M.user)
    log.info("P4HOST: " .. M.host)
    log.info("P4PORT: " .. M.port)
    log.info("P4CLIENT: " .. M.client)
end

--- Updates the P4 environment innformation from the shell's
--- environment.
local function update_from_env()
    M.user = os.getenv('P4USER')
    M.host = os.getenv('P4HOST')
    M.port = os.getenv('P4PORT')
    M.client = os.getenv('P4CLIENT')

    if M.user and M.host and M.port and M.client then
      log.info("P4 configured from enviroment")
      M.valid = true
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

    M.user = t["P4USER"]
    M.host = t["P4HOST"]
    M.port = t["P4PORT"]
    M.client = t["P4CLIENT"]

    if M.user and M.host and M.port and M.client then
      log.info("P4 configured from P4CONFIG")
      M.valid = true
    end
  end
end

--- Clears the P4 environment information
function M.clear()

    log.info("Clearing P4 config")

    -- NOTE: This does not clear the P4CONFIG path if it has been cached.

    M.valid = false
    M.user = nil
    M.host = nil
    M.port = nil
    M.client = nil
end

--- Updates the P4 environment information
function M.update()

  -- Prevent notifications if there is not P4CONFIG file
  -- in the workspace.
  if config.find() then

    -- If we have already cached the P4 environment
    -- information, then there is nothing to do.
    if M.valid == false then

      log.info("Configuring P4")

      -- Clear the current p4 environment information
      M.clear()

      -- Try to get P4 information from the shell enviroment
      -- (user using something like direnv).
      update_from_env()

      if M.valid == false then

        -- Need to find the P4CONFIG file to load p4 environment
        -- information.
        if config.path then

          -- Update the P4 environment information from the P4CONFIG
          -- file.
          update_from_file(config.path)
        end
      end

      -- Handle invalid configuration
      if M.valid then

        display_env()

        -- Enable autocmds
        require("p4.api.commands.file.ac").enable_autocmds()

        -- Set the P4 client
        require("p4.api.clients").set_client(M.client)
      else

        -- Disable autocmds
        require("p4.api.commands.file.ac").disable_autocmds()

        if not M.client then
          log.error("Invalid P4CLIENT")
        else
          if not M.port then
            log.error("Invalid P4PORT")
          else
            if not M.host then
              log.error("Invalid P4HOST")
            else
              if not M.user then
                log.error("Invalid P4USER")
              end
            end
          end
        end

        log.error("Configuring P4 failed")

        -- Clear the current p4 environment information
        M.clear()

      end
    end
  else
    -- Clear the current p4 environment information
    M.clear()
  end

  return M.valid
end

return M

