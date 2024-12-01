local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local log = require("p4.log")
local notify = require("p4.notify")


--- @class P4_Telescope_File_Actions
local P4_Telescope_File_Actions = {}

--- Gets the selected files for a file related action.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
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
    print(vim.inspect(actions_state.get_selected_entry()))

    table.insert(entry_list, actions_state.get_selected_entry())
  else
    notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
  end

  -- Close the previous prompt buffer.
  actions.close(prompt_bufnr)

  local p4_file_list = {}

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

--- Opens the picker's selected files for add.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.add(prompt_bufnr)

  log.trace("Telescope_File_Actions: add")

  local p4_file_list = get_selected_files(prompt_bufnr)

  p4_file_list:add(function(success)
    if not success then
      log.error("Telescope file action failed.")
    end
  end)
end

--- Opens the picker's selected files for edit.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.edit(prompt_bufnr)

  log.trace("Telescope_File_Actions: edit")

  local p4_file_list = get_selected_files(prompt_bufnr)

  p4_file_list:edit(function(success)
    if not success then
      log.error("Telescope file action failed.")
    end
  end)
end

--- Reverts the picker's selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.revert(prompt_bufnr)
  local p4_file_list = get_selected_files(prompt_bufnr)

  p4_file_list:revert(function(success)
    if not success then
      log.error("Telescope file action failed.")
    end
  end)
end

--- Opens the picker's selected files for delete.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.delete(prompt_bufnr)
  local p4_file_list = get_selected_files(prompt_bufnr)

  p4_file_list:delete(function(success)
    if not success then
      log.error("Telescope file action failed.")
    end
  end)
end

--- Gets file stats for each of the picker's selected files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.fstat(prompt_bufnr)

  log.trace("Telescope_File_Actions: fstat")

  local p4_file_list = get_selected_files(prompt_bufnr)

  p4_file_list:update_stats(function(success)
    if success then
      -- TODO: Print file stats
    else
      log.error("Telescope file action failed.")
    end
  end)
end

return P4_Telescope_File_Actions
