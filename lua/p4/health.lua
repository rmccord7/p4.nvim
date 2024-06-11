local health = vim.health or require "health"
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error

local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local mandatory_dependencies = {
  {
    name = "p4",
    url = "[Download P4](https://www.perforce.com/downloads/helix-visual-client-p4v)",
    optional = false,
  },
}

local required_plugins = {
  { lib = "telescope", optional = false },
}

local check_binary_installed = function(package)

  local binaries = package.binaries or { package.name }

  for _, binary in ipairs(binaries) do

    local found = vim.fn.executable(binary) == 1

    if not found and is_win then
      binary = binary .. ".exe"
      found = vim.fn.executable(binary) == 1
    end

    if found then
      local handle = io.popen(binary .. " -V")

      if handle then

        local output = handle:read "*a"

        local t = {}
        for _, line in ipairs(vim.split(output, "\n")) do
          table.insert(t, line)
        end

        local binary_version = t[#t-1]

        print(vim.inspect(binary_version))
        handle:close()

        return true, binary_version
      end
    end
  end
end

local function lualib_installed(lib_name)
  local res, _ = pcall(require, lib_name)
  return res
end

local M = {}

M.check = function()
  -- Required lua libs
  start "Checking for required plugins"
  for _, plugin in ipairs(required_plugins) do
    if lualib_installed(plugin.lib) then
      ok(plugin.lib .. " installed.")
    else
      local lib_not_installed = plugin.lib .. " not found."
      if plugin.optional then
        warn(("%s %s"):format(lib_not_installed, plugin.info))
      else
        error(lib_not_installed)
      end
    end
  end

  -- External dependencies
  start "Checking external dependencies"

  for _, package in ipairs(mandatory_dependencies) do
    local installed, version = check_binary_installed(package)
    if installed then
      -- local eol = version:find "\n"
      -- local ver = eol and version:sub(0, eol - 1) or "(unknown version)"
      ok(("%s: found %s"):format(package.name, version))
    else
      local err_msg = ("%s: not found."):format(package.name)
      if package.optional then
        warn(("%s %s"):format(err_msg, ("Install %s for extended capabilities"):format(package.url)))
      else
        error(
          ("%s"):format(
            err_msg,
            ("Plugin will not function without %s installed."):format(package.name)
          )
        )
      end
    end
  end
end

return M
