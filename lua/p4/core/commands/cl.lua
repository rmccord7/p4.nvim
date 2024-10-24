env = require("p4.core.env")

---@class P4_Read_Spec_Opts Options : table

---@class P4_Write_Spec_Opts Options : table

---@class P4_Read_Opts Options : table
---@field user? string Specifies the P4 user. If not specified P4USER will be used.
---@field client? string Specifies the P4 client. If not specified P4CLIENT will be used.
---@field pending? boolean Indicates whether pending changelists should be queried

---@class P4_Delete_Opts Options : table
---@field cl integer Specifies the P4 change list number

local M = {}

--- Returns the P4 command to read the specified change list
--- spec from the P4 server.
---
--- @param cl integer CL number.
--- @param opts? P4_Read_Spec_Opts Optional parameters.
---
--- @return table cmd Formatted P4 command
M.read_spec = function(cl, opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "change",
    "-o", -- to STDOUT
    cl,
  }

  return cmd
end

--- Returns the P4 command to write a change list
--- spec to the P4 server.
---
--- @param opts? P4_Write_Spec_Opts Optional parameters.
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
--- @param opts? P4_Read_Opts Optional parameters.
---
--- @return table cmd Formatted P4 command
M.read = function(opts)
  opts = opts or {}

  local cmd = {
    "p4",
    "changes",
  }

  -- Specify P4 user
  if opts.user then

    local ext_cmd = {
      "-u",
      opts.client,
    }

    vim.list_extend(cmd, ext_cmd)
  else
    local ext_cmd = {
      env.user,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  -- Specify P4 client
  if opts.client then

    local ext_cmd = {
      "-c",
      opts.client,
    }

    vim.list_extend(cmd, ext_cmd)
  else
    local ext_cmd = {
      "-c",
      env.client,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  -- Included pending CLs only
  if opts.pending then

    local ext_cmd = {
      "-s pending",
    }

    vim.list_extend(cmd, ext_cmd)
  end

  return cmd
end

--- Returns the P4 command to delete the specified change lists
--- from the P4 server.
---
--- @param file_spec string file_spec.
--- @param opts? P4_Delete_Opts Optional parameters.
---
--- @return table cmd Formatted P4 command
M.delete = function(file_spec, opts)

  opts = opts or {}

  local cmd = {
    "p4",
    "delete",
  }

  -- Specify change list
  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(cmd, ext_cmd)
  end

  -- File spec goes last
  local ext_cmd = {
    file_spec,
  }

  vim.list_extend(cmd, ext_cmd)

  return cmd
end

return M
