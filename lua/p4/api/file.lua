local util = require("p4.util")
local commands = require("p4.commands")

local core = require("p4.core")

--- P4 file
local M = {
  ac_group = nil, -- autocmd group ID
}

--- Prompts the user to open the file for add.
local function prompt_open_for_add(file_path)

    -- Ensure P4 environment information is valid
    if core.env.update() then

      vim.fn.inputsave()
      local result = vim.fn.input("Open for add (y/n): ")
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        M.add(file_path)
      end
    end
end

--- Prompts the user to open the file for edit.
local function promot_open_for_edit(file_path)

    -- Ensure P4 environment information is valid
    if core.env.update() then

      -- Prevent changing read only warning
      vim.api.nvim_set_option_value("readonly", false, { scope = "local" })

      vim.fn.inputsave()
      local opts = {prompt = '[P4] Open file for edit (y/n): ' }
      local _, result = pcall(vim.fn.input, opts)
      vim.fn.inputrestore()

      if result == "y" or result == "Y" then
        M.edit(file_path)
      else
        vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })

        -- Exit insert mode
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), 'm', false)
      end
    end
end

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

--- Enables autocmds
---
function M.enable_autocmds()

  M.ac_group = vim.api.nvim_create_augroup("P4_File", {})

  --- Check for P4 workspace when buffer is entered.
  ---
  vim.api.nvim_create_autocmd("BufEnter", {
    group = M.ac_group,
    pattern = "*",
    callback = function()

      if core.env.update() then

        -- Set buffer to reload for changes made outside vim such as
        -- pulling latest revisions.
        vim.api.nvim_set_option_value("autoread", false, { scope = "local" })

      end
    end,
  })

  vim.api.nvim_create_autocmd("BufNewFile", {
    group = M.ac_group,
    pattern = "*",
    callback = function()
      prompt_open_for_add()
    end,
  })

  --- If the buffer is written, then prompt the user whether they want
  --- the associated file opened for add/edit in the client workspace.
  ---
  vim.api.nvim_create_autocmd("BufWrite", {
    group = M.ac_group,
    pattern = "*",
    callback = function()
      if core.env.update() then
        local file_path = vim.fn.expand("%:p")
        local modifiable = vim.api.nvim_get_option_value("modifiable", { scope = "local" })

        if not modifiable then

          if vim.fn.filereadable(file_path) then

            promot_open_for_edit(file_path)

          else
            prompt_open_for_add(file_path)
          end
        end
      end
    end,
  })

  --- If the buffer is modified and read only, then prompt the user
  --- whether they want the associated file opened for edit in the
  --- client workspace.
  ---
  vim.api.nvim_create_autocmd("FileChangedRO", {
    group = M.ac_group,
    pattern = "*",
    callback = function()
        promot_open_for_edit()
    end,
  })
end

--- Disables autocmds
---
function M.disable_autocmds()

  if M.ac_group then

     -- Remove file autocmds
    vim.api.nvim_del_augroup_by_id(M.ac_group)

    M.ac_group = nil
  end
end

--- Adds one or more files to the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function M.add(file_paths, opts)
  opts = opts or {}

  local result = core.shell.run(commands.file.add(file_paths))

  if result.code == 0 then
    util.print("Opened for add")

    set_buffer_writeable()
  end
end

--- Checks out one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function M.edit(file_paths, opts)
  opts = opts or {}

  local result = core.shell.run(commands.file.edit(file_paths))

  if result.code == 0 then
    set_buffer_writeable()

    util.print("Opened for edit")
  end
end

--- Reverts one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function M.revert(file_paths, opts)
  opts = opts or {}

  local result = core.shell.run(commands.file.revert(file_paths, opts))

  if result.code == 0 then

    -- File was opened for edit so make buffer read only and not
    -- modifiable
    clear_buffer_writeable()

    util.print("Reverted files")
  end
end

--- Shelves one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function M.shelve(file_paths, opts)
  opts = opts or {}

  local result = core.shell.run(commands.file.shelve(file_paths, opts))

  if result.code == 0 then

    util.print("Shelved files")
  end
end

--- Gets information for one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function M.get_info(file_paths, opts)
  opts = opts or {}

  local info = {}

  local result = core.shell.run(commands.file.fstat(file_paths, opts))

  if result.code == 0 then

    for _, line in ipairs(vim.split(result.stdout, "\n")) do

      local t = util.split_str(line, "%s")

      if t[1] == "..." then
        info[t[2]] = t[3]
      end
    end
  end

  return info
end

return M

