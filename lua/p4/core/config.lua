local config = require("p4.config")
local log = require("p4.log")

--- P4 config
local M = {
    config_path = nil, -- path to config file
}

--- Clears the path to the P4CONFIG file.
function M.clear()
  M.config_path = nil
end

--- Finds the P4CONFIG file.
function M.find()
  log.trace("Finding P4CONFIG")
  log.debug("P4CONFIG: " .. config.opts.p4.config)

  M.config_path = vim.fs.find(config.opts.p4.config, {
    upward = true,
  })[1]

  if M.config_path then
    log.debug("P4 Config: " .. M.config_path)

    return true
  else
    log.debug("P4 Config: Not found")

    return false
  end
end

return M
