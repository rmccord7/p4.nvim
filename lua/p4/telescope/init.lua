---@class p4.telescope
local M = {}

-- Opens files for add in the client workspace.
function M.add(prompt_bufnr)
  local action_state = require("telescope.actions.state")

  ---@type Picker
  local picker = action_state.get_current_picker(prompt_bufnr)

  local file_paths = {}

  if #picker:get_multi_selection() > 0 then
    for _, file_path in ipairs(picker:get_multi_selection()) do
      table.insert(file_paths, file_path[1])
    end
  else
    for file_path in picker.manager:iter() do
      table.insert(file_path, file_path[1])
    end
  end

  vim.schedule(function()
    require("telescope.actions").close(prompt_bufnr)

    require("p4.api.file").add(file_paths)
  end)
end

-- Checks out files for edit in the client workspace.
function M.edit(prompt_bufnr)
  local action_state = require("telescope.actions.state")

  ---@type Picker
  local picker = action_state.get_current_picker(prompt_bufnr)

  local file_paths = {}

  if #picker:get_multi_selection() > 0 then
    for _, file_path in ipairs(picker:get_multi_selection()) do
      table.insert(file_paths, file_path[1])
    end
  else
    for file_path in picker.manager:iter() do
      table.insert(file_path, file_path[1])
    end
  end

  vim.schedule(function()
    require("telescope.actions").close(prompt_bufnr)

    require("p4.api.file").edit(file_paths)
  end)
end

-- Checks out files for edit in the client workspace.
function M.revert(prompt_bufnr)
  local action_state = require("telescope.actions.state")

  ---@type Picker
  local picker = action_state.get_current_picker(prompt_bufnr)

  local file_paths = {}

  if #picker:get_multi_selection() > 0 then
    for _, file_path in ipairs(picker:get_multi_selection()) do
      table.insert(file_paths, file_path[1])
    end
  else
    for file_path in picker.manager:iter() do
      table.insert(file_path, file_path[1])
    end
  end

  vim.schedule(function()
    require("telescope.actions").close(prompt_bufnr)

    require("p4.api.file").revert(file_paths)
  end)
end

-- Gets information for specified files.
function M.fstat(prompt_bufnr)
  local action_state = require("telescope.actions.state")

  ---@type Picker
  local picker = action_state.get_current_picker(prompt_bufnr)

  local file_paths = {}

  if #picker:get_multi_selection() > 0 then
    for _, file_path in ipairs(picker:get_multi_selection()) do
      table.insert(file_paths, file_path[1])
    end
  else
    for file_path in picker.manager:iter() do
      table.insert(file_path, file_path[1])
    end
  end

  vim.schedule(function()
    require("telescope.actions").close(prompt_bufnr)

    local files = require("p4.api.file").get_info(file_paths)

    if files and not vim.tbl_isempty(files) then
      vim.inspect(files)
    end
  end)
end

return M
