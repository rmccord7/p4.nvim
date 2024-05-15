local uv = vim.loop

local p4_config = require("p4.config")
local p4_util = require("p4.util")

--- P4 config
local M = {
    path = nil, -- path to config file
}

--- Clears the P4CONFIG path
function M.clear()
  M.path = nil
end

--- Find the P4CONFIG file
function M.find()
  p4_util.debug("Finding P4 Config")
  p4_util.debug("P4CONFIG: " .. p4_config.opts.p4.config)

  -- Check if we cached the P4config path the last time this
  -- function was called.
  if M.path == nil then

    -- Start at the CWD and go up until the P4CONFIG is found
    local path = p4_util.find_p4_ancestor(uv.cwd())

    if path then

      M.path = p4_util.path.sanitize(path .. "/" .. p4_config.opts.p4.config)

      p4_util.debug("Config Path: " .. M.path)

    else
      p4_util.debug("Config: Not found")
    end

  else

    p4_util.debug("P4 Config: " .. M.path)
    return true
  end
end

return M
