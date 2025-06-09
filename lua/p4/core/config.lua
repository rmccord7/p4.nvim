local config = require("p4.config")
local log = require("p4.log")

--- P4 config
local M = {
    config_path = nil, -- path to config file
}

--- Clears the P4CONFIG path
function M.clear()
  M.config_path = nil
end

--- Find the P4CONFIG file
function M.find()
  log.debug("Finding P4 Config")
  log.debug("P4CONFIG: " .. config.opts.p4.config)

  -- Check if we cached the P4config path the last time this
  -- function was called.
  if M.config_path == nil then

    M.config_path = vim.fs.find(config.opts.p4.config, {
      upward = true,
    })[1]

    log.debug("P4 Config: " .. M.config_path)

    return true
  else
    log.debug("P4 Config: Not found")

    return false
  end
end

return M
