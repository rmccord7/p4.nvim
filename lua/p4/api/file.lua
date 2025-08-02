local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_File_API
local P4_File_API = {}

--- Makes the current buffer writeable.
local function set_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
end

--- Makes the current buffer read only.
local function clear_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", true, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })
end

--- Adds one or more files to the client workspace.
---
--- @param file_path_list string[] One or more files.
--- @param opts? table Optional parameters. Not used.
--- @async
function P4_File_API.add(file_path_list, opts)

  log.trace("P4_File_API: add")

  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_path_list) == "table" and vim.tbl_isempty(file_path_list) then
    log.error("No files specified to add")
    return
  end

  nio.run(function()
    local P4_Command_Add = require("p4.core.lib.command.add")

    local cmd = P4_Command_Add:new(file_path_list)

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then
      vim.schedule(function()
        set_buffer_writeable()

        log.debug("Successfully added the file(s)")

        notify("File(s) opened for add")
      end)
    else
      log.debug("Failed to add the files: %s", sc.stderr)
    end
  end)
end

--- Checks out one or more files in the client workspace.
---
--- @param file_path_list string[] One or more files.
--- @param opts? table Optional parameters. Not used.
--- @async
function P4_File_API.edit(file_path_list, opts)

  log.trace("P4_File_API: edit")

  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_path_list) == "table" and vim.tbl_isempty(file_path_list) then
    log.debug("No files specified to edit")
    return
  end

  nio.run(function()
    local P4_Command_Edit = require("p4.core.lib.command.edit")

    local cmd = P4_Command_Edit:new(file_path_list)

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then
      vim.schedule(function()
        set_buffer_writeable()

        log.debug("Successfully edited the file(s)")

        notify("File(s) opened for edit")
      end)
    else
      log.debug("Failed to add the files: %s", sc.stderr)
    end
  end)
end

--- Reverts one or more files in the client workspace.
---
--- @param file_path_list string[] One or more files.
--- @param opts? table Optional parameters. Not used.
--- @async
function P4_File_API.revert(file_path_list, opts)

  log.trace("P4_File_API: revert")

  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_path_list) == "table" and vim.tbl_isempty(file_path_list) then
    log.debug("No files specified to revert")
    return
  end

  nio.run(function()
    local P4_Command_Revert = require("p4.core.lib.command.revert")

    local cmd = P4_Command_Revert:new(file_path_list)

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then
      vim.schedule(function()
        clear_buffer_writeable()

        log.debug("Successfully reverted the file(s)")

        notify("File(s) reverted")
      end)
    else
      log.debug("Failed to revert the files: %s", sc.stderr)
    end
  end)
end

--- Shelves one or more files in the client workspace.
---
--- @param file_path_list string[] One or more files.
--- @param opts? table Optional parameters. Not used.
--- @async
function P4_File_API.shelve(file_path_list, opts)

  log.trace("P4_File_API: shelve")

  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_path_list) == "table" and vim.tbl_isempty(file_path_list) then
    log.error("No files specified to shelve")
    return
  end

  nio.run(function()
    local P4_Command_Shelve = require("p4.core.lib.command.shelve")

    local cmd = P4_Command_Shelve:new(file_path_list)

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then
      log.debug("Successfully shelved the file(s)")

      notify("File(s) shelved")
    else
      log.debug("Failed to shelved the files: %s", sc.stderr)
    end
  end)
end

return P4_File_API
