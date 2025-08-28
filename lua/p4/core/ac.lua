---@class P4_Env : table
---@field ac_group? integer Autocommand group
local P4_AC = {
  ac_group = nil,
}

--- Prompts the user to open the file for add.
local function prompt_file_open_for_add(file_path)
  vim.fn.inputsave()
  local result = vim.fn.input("Open for add (y/n): ")
  vim.fn.inputrestore()

  if result == "y" or result == "Y" then
    local P4_File_API = require("p4.api.file")

    P4_File_API.add(file_path)
  end
end

--- Prompts the user to open the file for edit.
local function prompt_file_open_for_edit(file_path)
  -- Prevent changing read only warning.
  vim.api.nvim_set_option_value("readonly", false, { scope = "local" })

  vim.fn.inputsave()
  local opts = { prompt = "[P4] Open file for edit (y/n): " }
  local _, result = pcall(vim.fn.input, opts)
  vim.fn.inputrestore()

  if result == "y" or result == "Y" then
    local P4_File_API = require("p4.api.file")

    P4_File_API.edit({ file_path })
  else
    vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })

    -- Exit insert mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "m", false)
  end
end

--- Enables file autocmds.
---
function P4_AC.enable_file_autocmds()
  P4_AC.ac_group = vim.api.nvim_create_augroup("P4_File", {})

  -- Set buffer to reload for changes made outside vim such as
  -- pulling latest revisions.
  vim.api.nvim_create_autocmd("BufEnter", {
    group = P4_AC.ac_group,
    pattern = "*",
    callback = function()
      vim.api.nvim_set_option_value("autoread", false, { scope = "local" })
    end,
  })

  -- If we create a new buffer, then check if the user wants to add it to the
  -- workspace.
  vim.api.nvim_create_autocmd("BufNewFile", {
    group = P4_AC.ac_group,
    pattern = "*",
    callback = function()
      prompt_file_open_for_add(vim.fn.expand("%:p"))
    end,
  })

  --- If the buffer is written, then check if the user wants to add/edit it in
  --- the client workspace.
  vim.api.nvim_create_autocmd("BufWrite", {
    group = P4_AC.ac_group,
    pattern = "*",
    callback = function()
      local file_path = vim.fn.expand("%:p")
      local modifiable = vim.api.nvim_get_option_value("modifiable", { scope = "local" })

      if not modifiable then
        if vim.fn.filereadable(file_path) then
          prompt_file_open_for_edit(file_path)
        else
          prompt_file_open_for_add(file_path)
        end
      end
    end,
  })

  -- If the buffer is modified and read only, then prompt the user whether they
  -- want the associated file opened for edit in the client workspace.
  vim.api.nvim_create_autocmd("FileChangedRO", {
    group = P4_AC.ac_group,
    pattern = "*",
    callback = function()
      prompt_file_open_for_edit(vim.fn.expand("%:p"))
    end,
  })
end

--- Disables file autocmds.
---
function P4_AC.disable_file_autocmds()
  if P4_AC.ac_group then
    -- Remove file autocmds
    vim.api.nvim_del_augroup_by_id(P4_AC.ac_group)

    P4_AC.ac_group = nil
  end
end

return P4_AC
