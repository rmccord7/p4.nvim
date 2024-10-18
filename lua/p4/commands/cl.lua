local M = {}

--- Returns the P4 command to read the specified change list
--- spec from the P4 server.
---
--- @param opts? table Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.read_spec = function(changelist, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "change",
    "-o", -- to STDOUT
    changelist,
  }

  return cmd
end

--- Returns the P4 command to write a change list
--- spec to the P4 server.
---
--- @param opts? table Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.write_spec = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "change",
    "-i", -- To STDIN
  }

  return cmd
end

--- Returns the P4 command to read change lists
--- from the P4 server.
---
--- @param client string P4 client.
---
--- @param opts? table Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.read = function(client, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "changes",
    "--me", -- Current user
    "-c", -- Specify client
    client,
    "-s", -- Filter CL state
    "pending",
  }

  return cmd
end

return M
