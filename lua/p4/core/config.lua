local uv = vim.loop

local config = require("p4.config")
local util = require("p4.util")

local core_path = require("p4.core.path")

--- P4 config
local M = {
    path = nil, -- path to config file
}

-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L209
local function search_ancestors(startpath, func)
  vim.validate { func = { func, 'f' } }
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in core_path.iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L209
local function find_p4_ancestor(startpath)
  return search_ancestors(startpath, function(path)
    util.debug("Path" .. core_path.sanitize(core_path.join(path, config.opts.p4.config)))
    if core_path.is_file(core_path.join(path, config.opts.p4.config)) then
      return path
    end
  end)
end
--- Clears the P4CONFIG path
function M.clear()
  M.path = nil
end

--- Find the P4CONFIG file
function M.find()
  util.debug("Finding P4 Config")
  util.debug("P4CONFIG: " .. config.opts.p4.config)

  -- Check if we cached the P4config path the last time this
  -- function was called.
  if M.path == nil then

    -- Start at the CWD and go up until the P4CONFIG is found
    local path = find_p4_ancestor(uv.cwd())

    if path then

      M.path = core_path.sanitize(path .. "/" .. config.opts.p4.config)

      util.debug("Config Path: " .. M.path)

    else
      util.debug("Config: Not found")
    end

  else

    util.debug("P4 Config: " .. M.path)
    return true
  end
end

return M
