local debug = require("p4.commands.debug") -- Debugging for commands

local M = {}

--- Returns the P4 command to get information for the specified
--- file spec.
---
--- @param file_spec string
---
--- @param opts? table
---
--- @return table cmd Formatted P4 command
M.stat = function(file_spec, opts)
  opts = opts or {}

  -- file(s) not in client view.

  local cmd = {
    "p4",
    "fstat",
    file_spec,
  }

  debug.command(cmd)

  return cmd
end

--- Returns the P4 command to get location information for the
--- specified file spec.
---
--- @param file_path string
---
--- @param opts? table Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.where = function(file_path, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "where",
    file_path,
  }

  debug.command(cmd)

  return cmd
end

--- Returns the P4 command to open a file for add.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.add = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "add",
  }

  if type(file_paths) == 'table' then
    vim.list_extend(cmd, file_paths)
  else
    table.insert(cmd, file_paths)
  end

  debug.command(cmd)

  return cmd
end

--- Returns the P4 command to open a file for edit.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
--- @return table cmd Formatted P4 command
M.edit = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "edit",
  }

  if type(file_paths) == 'table' then
    vim.list_extend(cmd, file_paths)
  else
    table.insert(cmd, file_paths)
  end

  debug.command(cmd)

  return cmd
end

---@class P4_Revert_Cmd_Options : table
---@field cl? integer Reverts only the specified files in the
---                   specified change list.

--- Returns the P4 command to revert the specified files.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? P4_Revert_Cmd_Options Command options
---
--- @return table cmd Formatted P4 command
M.revert = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "revert",
    --"-n", -- Dry run
  }

  if opts.cl then

    local ext_cmd = {
      "-c", -- Revert files in specified CL
      opts.cl,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  if type(file_paths) == 'table' then
    vim.list_extend(cmd, file_paths)
  else
    table.insert(cmd, file_paths)
  end

  debug.command(cmd)

  return cmd
end

---@class P4_Shelve_Cmd_Options : table
---@field force? boolean Force shelving the files
---@field cl? integer Shelves only the specified files in the
---                   specified change list.

--- Returns the P4 command to shelve the specified files.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? P4_Shelve_Cmd_Options Command options
---
--- @return table cmd Formatted P4 command
M.shelve = function(file_paths, opts)
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
    table.insert(cmd, file_paths)
  end

  debug.command(cmd)

  return cmd
end

return M
