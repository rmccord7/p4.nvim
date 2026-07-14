local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

--- @class P4_Telescope_File_Actions
local P4_Telescope_File_Actions = {}

--- Gets the selected files for a file related action.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @return File_Path[] files P4 file list.
---
--- @nodiscard
local function get_selected_files(prompt_bufnr)
  ---@type Picker
  local picker = actions_state.get_current_picker(prompt_bufnr)

  local entry_list = {}

  if #picker:get_multi_selection() > 0 then
    for _, entry in ipairs(picker:get_multi_selection()) do
      table.insert(entry_list, entry[1])
    end
  elseif actions_state.get_selected_entry() ~= nil then
    table.insert(entry_list, actions_state.get_selected_entry())
  else
    notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
  end

  -- Close the previous prompt buffer.
  actions.close(prompt_bufnr)

  return entry_list
end

--- Opens the picker's selected file in a buffer.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.open(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      actions.file_edit(prompt_bufnr)
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Diffs the selected file with the head revision.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.diff(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Opens a file history picker to view the selected file's history.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.history(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Moves all selected files from one CL to another.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.move(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Opens the selected files for add.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.add(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then
    local success, results, error_results = xpcall(file_api.add, error_handler_api.process, files)

    if success then
      if #results > 0 then
        notify(string.format("file(s) opened for add:", files))
      end
    else
      for _, error_result in ipairs(error_results) do
        notify(string.format("%s: %s", error_result.depot_path, error_result.reason), vim.log.levels.WARN)
      end
    end
  end
end

--- Opens the selected files for edit.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.edit(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Reverts the selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.revert(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Opens the selected files for delete.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.delete(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Gets file stats for each of the selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.fstat(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Shelves all selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.shelve(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Un-shelves all selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
---
--- @async
--- @nodiscard
function P4_Telescope_File_Actions.unshelve(prompt_bufnr)
  local files = get_selected_files(prompt_bufnr)

  if #files > 0 then

    -- Only allow one selection for this action.
    if #files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

return P4_Telescope_File_Actions
