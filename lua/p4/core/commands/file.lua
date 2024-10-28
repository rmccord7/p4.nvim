local M = {}

---@class P4_Fstat_Cmd_Options : table
---@field cl? integer Only files in the specified changelist.

---@class P4_Fstat : table
---@field clientFile string Local path to the file in local syntax
---@field DepotFile string Depot path to the file
---@field path string Local path to the file
---@field isMapped boolean Indicates if file is mapped to the current client workspace
---@field shelved boolean Indicates if file is shelved
---@field change integer Open change list number if file is opened in client workspace
---@field headRev integer Head revision number if in depot
---@field haveRev integer Revision last synced to workpace
---@field workRev integer Revision if file is opened
---@field action string Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive)

--- Returns the P4 command to get information for the specified
--- file spec.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table
---
--- @return P4_Fstat fstat File information
M.fstat = function(file_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "fstat",
  }

  if type(file_paths) == 'table' then
    vim.list_extend(cmd, file_paths)
  else
    table.insert(cmd, file_paths)
  end

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

  return cmd
end

---@class P4_Filelog_Cmd_Options : table
---@field cl? integer Display only files submitted at the
---                   specific changelist number.
---@field follow? boolean Follow a file's hisory across branches.

--- Returns the P4 command to print information about a file's history.
---
--- @param files_paths string File path
---
--- @param opts? P4_Filelog_Cmd_Options Command options
---
--- @return table cmd Formatted P4 command
M.filelog = function(files_paths, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "filelog",
  }

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  if opts.follow then

    local ext_cmd = {
      "-i",
    }

    vim.list_extend(cmd, ext_cmd)
  end

  table.insert(cmd, files_paths)

  return cmd
end

return M
