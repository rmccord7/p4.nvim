local p4_util = require("p4.util")
local p4c_config = require("p4.core.config")

--- P4 env
local M = {
    valid = false, -- indicates if p4 enviroment information is valid
    user = nil, -- identifies the P4 user
    host = nil, -- identifies the P4 host
    port = nil, -- identifies the P4 port
    client = nil, -- identifies the P4 client
    file_ac_group = nil, -- File autogroup ID
    dir_ac_group = nil, -- Dir autogroup ID
}


--- Enables dir autocmds
---
local function enable_dir_autocmds()
  M.dir_ac_group = vim.api.nvim_create_augroup("P4_Dir", {})

  --- If directory has changed, then we may have left the
  --- current P4 workspace.
  ---
  vim.api.nvim_create_autocmd({"DirChanged"}, {
    group = M.dir_ac_group,
    pattern = "*",
    callback = function()

      -- Force search for the new P4CONFIG since directory changed.
      p4c_config.clear()

      -- NOTE: Even if a new P4CONFIG file is found, then P4 enviornment
      --       information from the shell environment will have priority.

      -- Force the P4 environment information update
      M.clear()
      M.update()
    end,
  })
end

--- Disables dir autocmds
---
local function disable_dir_autocmds()
  if M.dir_ac_group then

     -- Remove file autocmds
    vim.api.nvim_del_augroup_by_id(M.ac_group)

    M.ac_group = nil
  end
end

--- Displays P4 environment information.
local function display_env()
    p4_util.debug("P4USER: " .. M.user)
    p4_util.debug("P4HOST: " .. M.host)
    p4_util.debug("P4PORT: " .. M.port)
    p4_util.debug("P4CLIENT: " .. M.client)
end

--- Updates the P4 environment innformation from the shell's
--- environment.
local function update_from_env()
    M.user = os.getenv('P4USER')
    M.host = os.getenv('P4HOST')
    M.port = os.getenv('P4PORT')
    M.client = os.getenv('P4CLIENT')

    if M.user and M.host and M.port and M.client then
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

    if M.user and M.p4.host and M.p4.port and M.p4.client then
      M.valid = true
    end
  end
end

--- Clears the P4 environment information
function M.clear()

    p4_util.debug("Clearing P4 Environment")

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
  if p4c_config.find() then

    -- If we have already cached the P4 environment
    -- information, then there is nothing to do.
    if M.valid == false then

      p4_util.debug("Updating P4 Environment")

      -- Clear the current p4 environment information
      M.clear()

      -- Try to get P4 information from the shell enviroment
      -- (user using something like direnv).
      update_from_env()

      if M.valid == false then

        -- Need to find the P4CONFIG file to load p4 environment
        -- information.
        if p4c_config.path then

          -- Update the P4 environment information from the P4CONFIG
          -- file.
          update_from_file(p4c_config.path)
        end
      end

      -- Handle invalid configuration
      if M.valid then

        p4_util.debug("ENV: Valid")

        display_env()

        -- Enable autocmds
        require("p4.core.file").enable_autocmds()
        enable_dir_autocmds()

      else

        p4_util.debug("ENV: Invalid")

        -- Disable autocmds
        require("p4.core.file").disable_autocmds()
        disable_dir_autocmds()

        if not M.client then
          p4_util.error("Invalid client")
        else
          if not M.port then
            p4_util.error("Invalid port")
          else
            if not M.host then
              p4_util.error("Invalid host")
            else
              if not M.user then
                p4_util.error("Invalid user")
              end
            end
          end
        end

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

