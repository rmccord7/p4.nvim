p4_config = require("p4.config")

M = {}

M.check_login = function(opts)
  opts = opts or {}

  return {
    "p4",
    "login",
    "-s",
  }
end

M.where_file = function(file_path, opts)
  opts = opts or {}

  return {
    "p4",
    "where",
    file_path,
  }
end

M.add_file = function(file_path, opts)
  opts = opts or {}

  return {
    "p4",
    "add",
    file_path,
  }
end

M.edit_file = function(file_path, opts)
  opts = opts or {}

  return {
    "p4",
    "edit",
    file_path,
  }
end

M.revert_file = function(file_paths, opts)
  opts = opts or {}

  local file_paths

  if type(file_paths) == 'table' then
    file_paths = table.concat(file_paths, ' ')
  end

  return {
    "p4",
    "revert",
    "-n",
    file_paths,
  }
end

M.read_client = function(client, opts)
  opts = opts or {}

  return {
    "p4",
    "client",
    "-o",
    client,
  }
end

M.write_client = function(opts)
  opts = opts or {}

  return {
    "p4",
    "client",
    "-i",
  }
end

M.read_clients = function(opts)
  opts = opts or {}

  return {
    "p4",
    "clients",
    "--me",
  }
end

M.read_change_list = function(changelist, opts)
  opts = opts or {}

  return {
    "p4",
    "change",
    "-o",
    changelist,
  }
end

M.write_change_list = function(opts)
  opts = opts or {}

  return {
    "p4",
    "change",
    "-i",
  }
end

M.read_change_lists = function(client, opts)
  client = client or p4_config.opts.p4.client

  opts = opts or {}


  return {
    "p4",
    "changes",
    "--me",
    "-c",
    client,
    "-s",
    "pending",
  }
end

M.read_change_list_files = function(changelist, opts)
  opts = opts or {}

  return {
    "p4",
    "opened",
    "-c",
    changelist,
  }
end

M.delete_change_list = function(opts)
  opts = opts or {}

  return {
    "p4",
    "changes",
    "--me",
    "-c",
    p4_config.opts.p4.client,
    "-s",
    "pending",
  }
end

M.revert_change_list = function(opts)
  opts = opts or {}

  return {
    "p4",
    "changes",
    "--me",
    "-c",
    p4_config.opts.p4.client,
    "-s",
    "pending",
  }
end

return M
