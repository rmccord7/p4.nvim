local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local tp4_util = require("telescope._extensions.p4.pickers.util")

local M = {}

--- Telescope picker to display a P4 change list's files that
--- are checked out in the client workspace.
---
--- @param cl P4_CL Change list.
---
--- @param opts table? Optional parameters. Not used.
---
function M.files_picker(cl, opts)
  opts = opts or {}

  --- Defines mappings.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  --- @param map function Maps keys to functions.
  ---
  local function attach_mappings(prompt_bufnr, map)

    -- Replace select default option.
    actions.select_default:replace(function()

      -- Close the prompt.
      actions.close(prompt_bufnr)

      -- Get the selected entry.
      local entry = actions_state.get_selected_entry()

      -- In case the user didn't select one or more entries before
      -- performing an action.
      if not entry then
        tp4_util.warn_no_selection_action()
        return
      end
    end)

    local cl_mappings = require("p4_config.opts.telescope.change_lists.mappings")
    local cl_actions = require("telescope._extensions.p4.pickers.cl.actions")

    map({ "i", "n" }, cl_mappings.diff, cl_actions.diff_files)
    map({ "i", "n" }, cl_mappings.revert, cl_actions.revert_files)
    map({ "i", "n" }, cl_mappings.shelve, cl_actions.shelve_files)
    map({ "i", "n" }, cl_mappings.unshelve, cl_actions.unshelve_files)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "Change List",
      results_title = "Checked Out",
      finder = finders.new_table({
        results = cl.files,
      }),
      sorter = config.generic_sorter(opts),
      previewer = config.file_previewer(opts),
      attach_mappings = attach_mappings,
    })
    :find()
end

return M
