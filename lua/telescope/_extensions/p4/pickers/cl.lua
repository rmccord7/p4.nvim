local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local p4_config = require("p4.config")
local p4_commands = require("p4.commands")
local p4_core = require("p4.core")
local p4_api = require("p4.api")

local tp4_actions = require("telescope._extensions.p4.actions")
local tp4_util = require("telescope._extensions.p4.pickers.util")

local M = {}

--- Telescope picker to display a P4 change list's files that
--- are checked out in the client workspace.
---
--- @param files string[] List of files.
---
--- @param opts table? Optional parameters. Not used.
---
function M.files_picker(files, opts)
  opts = opts or {}

  -- Make sure we are logged in.
  if not p4_api.login.check() then
    return
  end

  --- Diffs the P4 change list's files against the head revision.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  local function diff_files(prompt_bufnr)
  end

  --- Reverts the P4 change list's files.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  local function revert_files(prompt_bufnr)

    local selection = tp4_actions.get_selection(prompt_bufnr)

    if selection then
      p4_core.shell.run(p4_commands.file.revert(selection,{force = true, cl = opts.cl}))
    end
  end

  --- Shelves the P4 change list's files.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  local function shelve_files(prompt_bufnr)

    local selection = tp4_actions.get_selection(prompt_bufnr)

    if selection then
      p4_core.shell.run(p4_commands.file.shelve(selection,{force = true, cl = opts.cl}))
    end
  end

  --- Un-shelves the P4 change list's files.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  local function unshelve_files(prompt_bufnr)
    return
  end

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

    map({ "i", "n" }, p4_config.opts.telescope.change_list.mappings.diff, diff_files)
    map({ "i", "n" }, p4_config.opts.telescope.change_list.mappings.revert, revert_files)
    map({ "i", "n" }, p4_config.opts.telescope.change_list.mappings.shelve, shelve_files)
    map({ "i", "n" }, p4_config.opts.telescope.change_list.mappings.unshelve, unshelve_files)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "Change List",
      results_title = "Checked Out",
      finder = finders.new_table({
        results = files,
      }),
      sorter = config.generic_sorter(opts),
      previewer = config.file_previewer(opts),
      attach_mappings = attach_mappings,
    })
    :find()
end

return M
