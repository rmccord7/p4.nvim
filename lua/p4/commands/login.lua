local M = {}

---@class P4_Login_Cmd_Options : table
---@field check? boolean Check if user is logged into P4 server. Password
---                      ignored if this option is set to true.

--- Returns the P4 command to login to the P4 server.
---
--- @param opts? P4_Login_Cmd_Options Command options
---
--- @param password? string Password. Ignored if opts.check is true.
---
--- @return table cmd Formatted P4 command
---
M.login = function(opts, password)
  opts = opts or {}

  local cmd = {
    "p4",
    "login",
  }

  -- Check login
  if opts.check then

    local ext_cmd = {
      "-s",
    }

    vim.list_extend(cmd, ext_cmd)
  else
    vim.list_extend(cmd, {password})
  end

  return cmd
end

return M
