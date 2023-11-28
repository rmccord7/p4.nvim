p4_config = require("p4.config")
p4_util = require("p4.util")

local function debug_command(cmd)

  if type(cmd) == 'table' then
    p4_util.debug(string.format("Command: '%s'", table.concat(cmd, ' ')))
  else
    p4_util.debug(string.format("Command: '%s'", cmd))
  end
end


M = {}

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

M.add_file = function(file_path, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "add",
    file_path,
  }

  debug_command(cmd);

  return cmd
end

M.edit_file = function(file_path, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "edit",
    file_path,
  }

  debug_command(cmd);

  return cmd
end

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

M.read_clients = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "clients",
    "--me",
  }

  debug_command(cmd);

  return cmd
end

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
