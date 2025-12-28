local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_CL_Actions
local P4_Telescope_CL_Actions = {}

--- Gets the selected cls for a cl related action.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
local function get_selected_cls(prompt_bufnr)

  log.trace("Telescope_CL_Actions: get_selected_cls")

  ---@type Picker
  local picker = actions_state.get_current_picker(prompt_bufnr)

  -- Generate the list of cls from the prompt buffer's picker.
  local p4_cl_list = {}

  if #picker:get_multi_selection() > 0 then
    for _, entry in ipairs(picker:get_multi_selection()) do
      table.insert(p4_cl_list, entry.value)
    end
  else
    local entry = actions_state.get_selected_entry()
    if entry then
      table.insert(p4_cl_list, entry.value)
    else
      log.debug("No CL selected")

      notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
    end
  end

  -- Close the previous prompt buffer.
  actions.close(prompt_bufnr)

  return p4_cl_list
end

--- Action to open a telescope picker for the CL's files.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_CL_Actions.display_cl_files(prompt_bufnr)

  log.trace("Telescope_CL_Actions: display_cl_files")

  --- @type P4_CL[]
  local p4_cl_list = get_selected_cls(prompt_bufnr)

  if not vim.tbl_isempty(p4_cl_list) then

    if #p4_cl_list == 1 then

      --- @type P4_CL
      local p4_cl = p4_cl_list[1]

      local success, p4_file_list = p4_cl:get_file_list()

      if success and p4_file_list then

        -- Run the telescope file picker.
        local picker = require("telescope._extensions.p4.pickers.file")

        picker.load("CL: " .. p4_cl:get_change(), p4_file_list)
      end
    else
      notify("Only 1 CL may be selected for this action.", vim.log.levels.WARN)
    end
  end
end

return P4_Telescope_CL_Actions
