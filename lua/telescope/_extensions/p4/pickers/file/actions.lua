local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

--- @class P4_Telescope_File_Actions
local P4_Telescope_File_Actions = {}

--- Gets the selected files for a file related action.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
local function get_selected_files(prompt_bufnr)

  ---@type Picker
  local picker = actions_state.get_current_picker(prompt_bufnr)

  -- Generate the list of files from the prompt buffer's picker.
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

  -- Close the previous prompt buffer.
  actions.close(prompt_bufnr)

  local P4_File_List = require("p4.core.lib.file_list")

  local p4_file_list = P4_File_List:new(file_paths)

  return p4_file_list
end

--- Opens the picker's selected files for add.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_File_Actions.add(prompt_bufnr)
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
