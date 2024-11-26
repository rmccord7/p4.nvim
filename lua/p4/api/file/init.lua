local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_File_API
local file_api = {}

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

----@param on_exit fun(success: boolean,...) Callback to invoke when the task is complete. If success is false then the parameters will be an error message and a traceback of the error, otherwise it will be the result of the async function.

--- Adds one or more files to the client workspace.
---
--- @param file_paths string|string[] One or more files.
--- @param opts? table Optional parameters. Not used.
function file_api.add(file_paths, opts)
  --- @diagnostic disable-next-line String[] not recognized as table
  vim.validate("file_paths", file_paths, {"string", "table"})
  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_paths) == "string" and file_paths == "" then
    log.error("No files specified to add")
    return
  end

  if type(file_paths) == "table" and vim.tbl_isempty(file_paths) then
    log.error("No files specified to add")
    return
  end

  nio.run(function()
    P4_Command_Add = require("p4.core.lib.command.add")

    local cmd = P4_Command_Add:new(file_paths)

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
--- @param file_paths string|string[] One or more files.
--- @param opts? table Optional parameters. Not used.
function file_api.edit(file_paths, opts)
  --- @diagnostic disable-next-line String[] not recognized as table
  vim.validate("file_paths", file_paths, {"string", "table"})
  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_paths) == "string" and file_paths == "" then
    log.debug("No files specified to edit")
    return
  end

  if type(file_paths) == "table" and vim.tbl_isempty(file_paths) then
    log.debug("No files specified to edit")
    return
  end

  nio.run(function()
    P4_Command_Edit = require("p4.core.lib.command.edit")

    local cmd = P4_Command_Edit:new(file_paths)

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
--- @param file_paths string|string[] One or more files.
--- @param opts? table Optional parameters. Not used.
function file_api.revert(file_paths, opts)
  --- @diagnostic disable-next-line String[] not recognized as table
  vim.validate("file_paths", file_paths, {"string", "table"})
  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_paths) == "string" and file_paths == "" then
    log.debug("No files specified to revert")
    return
  end

  if type(file_paths) == "table" and vim.tbl_isempty(file_paths) then
    log.debug("No files specified to revert")
    return
  end

  nio.run(function()
    P4_Command_Revert = require("p4.core.lib.command.revert")

    local cmd = P4_Command_Revert:new(file_paths)

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
--- @param file_paths string|string[] One or more files.
--- @param opts? table Optional parameters. Not used.
function file_api.shelve(file_paths, opts)
  --- @diagnostic disable-next-line String[] not recognized as table
  vim.validate("file_paths", file_paths, {"string", "table"})
  vim.validate("opts", opts, "table", true)

  opts = opts or {}

  if type(file_paths) == "string" and file_paths == "" then
    log.error("No files specified to shelve")
    return
  end

  if type(file_paths) == "table" and vim.tbl_isempty(file_paths) then
    log.error("No files specified to shelve")
    return
  end

  nio.run(function()
    P4_Command_Shelve = require("p4.core.lib.command.shelve")

    local cmd = P4_Command_Shelve:new(file_paths)

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

return file_api
