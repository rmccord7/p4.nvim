local nio = require("nio")

local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local log = require("p4.log")
local notify = require("p4.notify")
local task = require("p4.task")

--- @class P4_Telescope_File_Actions
local P4_Telescope_File_Actions = {}

--- Gets the selected files for a file related action.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @return P4_File_List? result P4 file list.
--- @nodiscard
local function get_selected_files(prompt_bufnr)

  log.trace("Telescope_File_Actions: get_selected_files")

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

  local p4_file_list = nil

  if #entry_list then

    -- Convert entry list to file list.
    local p4_files = {}

    for _, entry in ipairs(entry_list) do

      table.insert(p4_files, entry.value)
    end

    local P4_File_List = require("p4.core.lib.file_list")

    p4_file_list = P4_File_List:build(p4_files)
  end

  return p4_file_list
end

--- Opens the picker's selected file in a buffer.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.open(prompt_bufnr)

  log.trace("Telescope_File_Actions: open")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    -- Only allow one selection for this action.
    if #p4_file_list:get().files == 1 then
      actions.file_edit(prompt_bufnr)
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Diffs the selected file with the head revision.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.diff(prompt_bufnr)

  log.trace("Telescope_File_Actions: diff")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    -- Only allow one selection for this action.
    if #p4_file_list:get().files == 1 then
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

  log.trace("Telescope_File_Actions: history")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    -- Only allow one selection for this action.
    if #p4_file_list:get().files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Moves all selected files from one CL to another.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.move(prompt_bufnr)

  log.trace("Telescope_File_Actions: move")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    -- Only allow one selection for this action.
    if #p4_file_list:get().files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Opens the selected files for add.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.add(prompt_bufnr)

  log.trace("Telescope_File_Actions: add")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    nio.run(function()

      local success, _ = pcall(p4_file_list:add().wait)

      if not success then
        log.error("Telescope file action failed.")
      end
    end, function(success, ...)
      task.complete(nil, success, ...)
    end)
  end
end

--- Opens the selected files for edit.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.edit(prompt_bufnr)

  log.trace("Telescope_File_Actions: edit")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    nio.run(function()

      local success, _ = pcall(p4_file_list:edit().wait)

      if not success then
        log.error("Telescope file action failed.")
      end
    end, function(success, ...)
      task.complete(nil, success, ...)
    end)
  end
end

--- Reverts the selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.revert(prompt_bufnr)

  log.trace("Telescope_File_Actions: revert")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    nio.run(function()

      local success, _ = pcall(p4_file_list:revert().wait)

      if not success then
        log.error("Telescope file action failed.")
      end
    end, function(success, ...)
      task.complete(nil, success, ...)
    end)
  end
end

--- Opens the selected files for delete.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.delete(prompt_bufnr)

  log.trace("Telescope_File_Actions: delete")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    nio.run(function()

      local success, _ = pcall(p4_file_list:delete().wait)

      if not success then
        log.error("Telescope file action failed.")
      end
    end, function(success, ...)
      task.complete(nil, success, ...)
    end)
  end
end

--- Gets file stats for each of the selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.fstat(prompt_bufnr)

  log.trace("Telescope_File_Actions: fstat")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    nio.run(function()

      local success, _ = pcall(p4_file_list:update_stats().wait)

      if not success then
        log.error("Telescope file action failed.")
      end
    end, function(success, ...)
      task.complete(nil, success, ...)
    end)
  end
end

--- Shelves all selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.shelve(prompt_bufnr)

  log.trace("Telescope_File_Actions: shelve")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    -- Only allow one selection for this action.
    if #p4_file_list:get().files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

--- Un-shelves all selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @async
function P4_Telescope_File_Actions.unshelve(prompt_bufnr)

  log.trace("Telescope_File_Actions: unshelve")

  --- @type P4_File_List?
  local p4_file_list = get_selected_files(prompt_bufnr)

  -- No valid selection.
  if p4_file_list then

    -- Only allow one selection for this action.
    if #p4_file_list:get().files == 1 then
      notify("Action not supported yet.")
    else
      notify("Only 1 file may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

return P4_Telescope_File_Actions
