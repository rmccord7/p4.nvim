p4_config = require("p4.config")
p4_util = require("p4.util")

--- Prints P4 command as a string.
---
--- @param cmd string|table
local function debug_command(cmd)

  if type(cmd) == 'table' then
    p4_util.debug(string.format("Command: '%s'", table.concat(cmd, ' ')))
  else
    p4_util.debug(string.format("Command: '%s'", cmd))
  end
end

---@class P4Commands
---@field buf number|nil
---@field win number|nil
---@field severity lsp.DiagnosticSeverity|nil

M = {}

--- Returns the P4 command to login to the P4 server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
---
M.login = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "login",
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to check if the user is logged
--- into the P4 server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
---
M.check_login = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "login",
    "-s",
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to get information for the specified
--- file spec.
---
--- @param file_spec string
---
--- @param opts table|nil
---
--- @return table cmd
M.file_stat = function(file_spec, opts)
  opts = opts or {}

  -- file(s) not in client view.

  local cmd = {
    "p4",
    "fstat",
    file_spec,
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to get location information for the
--- specified file spec.
---
--- @param file_path string
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.where_file = function(file_path, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "where",
    file_path,
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to open a file for add.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.add_file = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "add",
    file_paths,
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to open a file for edit.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.edit_file = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "edit",
    file_paths,
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to revert the specified files.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts table? Optional parameters.
---               • cl : Reverts only the specified files in the
---                      specified change list.
---
--- @return table cmd Formatted P4 command
M.revert_file = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "revert",
    "-n",
  }

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  if type(file_paths) == 'table' then
    vim.list_extend(cmd, file_paths)
  else
    table.insert(cmd, #cmd, file_paths);
  end

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to shelve the specified files.
---
--- @param file_paths string[] One or more files.
---
--- @param opts table? Optional parameters.
---               • cl : Shelves only the specified files in the
---                      specified change list.
---
--- @return table cmd
M.shelve_file = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "shelve",
  }

  if opts.force then
    table.insert(cmd, #cmd, "-f")
  end

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  if type(file_paths) == 'table' then
    vim.list_extend(cmd, file_paths)
  else
    table.insert(cmd, #cmd, file_paths);
  end

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to read the specified client spec from
--- the P4 server.
---
--- @param client string P4 client.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.read_client = function(client, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "client",
    "-o",
    client,
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to write the client spec to the
--- P4 server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.write_client = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "client",
    "-i",
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to read P4 clients from the P4
--- server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.read_clients = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "clients",
    "--me", -- Current user clients
    "-a", -- Get all clients (not just the ones on the connected p4 server)
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to read the specified change list
--- spec from the P4 server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.read_change_list = function(changelist, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "change",
    "-o",
    changelist,
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to write a change list
--- spec to the P4 server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.write_change_list = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "change",
    "-i",
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to read change lists
--- from the P4 server.
---
--- @param client string P4 client.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.read_change_lists = function(client, opts)
  client = client or p4_config.opts.p4.client

  opts = opts or {}

  local cmd = {
    "p4",
    "changes",
    "--me",
    "-c",
    client,
    "-s",
    "pending",
  }

  debug_command(cmd);

  return cmd
end

--- Returns the P4 command to read files from the specified
--- change list.
---
--- @param changelist string P4 change list.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd
M.read_change_list_files = function(changelist, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "opened",
    "-c",
    changelist,
  }

  debug_command(cmd);

  return cmd
end

return M
