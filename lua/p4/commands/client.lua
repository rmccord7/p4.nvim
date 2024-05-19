local debug = require("p4.commands.debug") -- Debugging for commands

M = {}

--- Returns the P4 command to read the specified client spec from
--- the P4 server.
---
--- @param client string P4 client.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.read_spec = function(client, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "client",
    "-o", -- To STDOUT
    client,
  }

  debug.command(cmd)

  return cmd
end

--- Returns the P4 command to write the client spec to the
--- P4 server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.write_spec = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "client",
    "-i", -- To STDIN
  }

  debug.command(cmd)

  return cmd
end

--- Returns the P4 command to read P4 clients from the P4
--- server.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.read = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "clients",
    "--me", -- Current user
    "-a", -- Get all clients (not just the ones on the connected p4 server)
  }

  debug.command(cmd)

  return cmd
end

--- Returns the P4 command to read files from the specified
--- change list.
---
--- @param changelist string P4 change list.
---
--- @param opts table? Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.read_change_list_files = function(changelist, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "opened",
    "-c", -- Specify CL
    changelist,
  }

  debug.command(cmd)

  return cmd
end

return M
