local uv = vim.loop

local config = require("p4.config")

local log = require("p4.log")
local path = require("p4.core.path")

--- P4 config
local M = {
    config_path = nil, -- path to config file
}

-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L209
local function search_ancestors(startpath, func)

  vim.validate { func = { func, 'f' } }
  if func(startpath) then
    return startpath
  end
  local guard = 100

  for p in path.iterate_parents(startpath) do

    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(p) then
      return p
    end
  end
end

-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L209
local function find_p4_ancestor(startpath)
  return search_ancestors(startpath, function(p)
    log.debug("Path" .. path.sanitize(path.join(p, config.opts.p4.config)))
    if path.is_file(path.join(p, config.opts.p4.config)) then
      return p
    end
  end)
end

--- Clears the P4CONFIG path
function M.clear()
  M.path = nil
end

--- Find the P4CONFIG file
function M.find()
  log.debug("Finding P4 Config")
  log.debug("P4CONFIG: " .. config.opts.p4.config)

  -- Check if we cached the P4config path the last time this
  -- function was called.
  if M.config_path == nil then

    -- Start at the CWD and go up until the P4CONFIG is found
    local config_root = find_p4_ancestor(uv.cwd())

    if config_root then

      M.config_path = path.sanitize(config_root .. "/" .. config.opts.p4.config)

      log.debug("Config Path: " .. M.config_path)
    else
    end
  end

  if M.config_path then
    log.debug("P4 Config: " .. M.config_path)
    return true
  else
    log.debug("P4 Config: Not found")
    return false
  end
end

return M
