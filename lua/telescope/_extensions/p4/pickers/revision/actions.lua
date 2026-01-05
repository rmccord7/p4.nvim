local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Revision_Actions
local P4_Telescope_Revision_Actions = {}

--- Helper function to gets the selected revisions.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
--- @return boolean success Indicates the result of the function.
--- @return P4_Revision[]? revisions Holds the selected P4 revisions if this function is successful.
---
--- @nodiscard
local function get_selected_revisions(prompt_bufnr)
  log.trace("Telescope_Revision_Actions (get_selected_revisions): Enter")

  local success = true

  ---@type Picker
  local picker = actions_state.get_current_picker(prompt_bufnr)

  ---@type P4_Revision[]
  local revision_list = {}

  if #picker:get_multi_selection() > 0 then
    for _, entry in ipairs(picker:get_multi_selection()) do
      table.insert(revision_list, entry.value)
    end
  else
    local entry = actions_state.get_selected_entry()
    if entry then
      table.insert(revision_list, entry.value)
    else
      log.debug("No Revision selected")

      notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
    end
  end

  if success then
    actions.close(prompt_bufnr)
  end

  log.trace("Telescope_Revision_Actions (get_selected_revisions): Exit")

  return success, revision_list
end

--- Action to diff the the selected revision against the workspace file.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_Revision_Actions.diff_against_workspace_file(prompt_bufnr)
  log.trace("Telescope_Revision_Actions (diff_against_workspace_file): Enter")

  local success, revision_list = get_selected_revisions(prompt_bufnr)

  if success and revision_list then

    if #revision_list == 1 then

      --- @type P4_Revision
      -- local revision = revision_list[1]

      notify("Not supported", vim.log.level.ERROR);
    else
      notify("Only 1 revision may be selected for this action.", vim.log.levels.WARN)
    end
  end

  log.trace("Telescope_Revision_Actions (diff_against_workspace_file): Exit")
end

--- Action to diff the the selected revision against the head revision.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_Revision_Actions.diff_against_head_revision(prompt_bufnr)
  log.trace("Telescope_Revision_Actions (diff_against_workspace_file): Enter")

  local success, revision_list = get_selected_revisions(prompt_bufnr)

  if success and revision_list then

    if #revision_list == 1 then

      --- @type P4_Revision
      -- local revision = revision_list[1]

      notify("Not supported", vim.log.level.ERROR);
    else
      notify("Only 1 revision may be selected for this action.", vim.log.levels.WARN)
    end
  end

  log.trace("Telescope_Revision_Actions (diff_against_workspace_file): Exit")
end

--- Action to diff the the selected revision against the previous revision.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_Revision_Actions.diff_against_previous_revision(prompt_bufnr)
  log.trace("Telescope_Revision_Actions (diff_against_workspace_file): Enter")

  local success, revision_list = get_selected_revisions(prompt_bufnr)

  if success and revision_list then

    if #revision_list == 1 then

      --- @type P4_Revision
      -- local revision = revision_list[1]

      notify("Not supported", vim.log.level.ERROR);
    else
      notify("Only 1 revision may be selected for this action.", vim.log.levels.WARN)
    end
  end

  log.trace("Telescope_Revision_Actions (diff_against_workspace_file): Exit")
end

return P4_Telescope_Revision_Actions
