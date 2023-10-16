local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local telescope_p4_config = require("telescope._extensions.p4.config")
local telescope_p4_pickers_util = require("telescope._extensions.p4.pickers.util")

local p4_commands = require("p4.commands")
local p4_util = require("p4.util")

local M = {}

function M.files_picker(files, opts)
  opts = opts or {}

  if not telescope_p4_pickers_util.verify_p4_picker() then
    return
  end

  local function diff_files(prompt_bufnr)
  end

  local function revert_files(prompt_bufnr)
    local selection = {}

    local picker = actions_state.get_current_picker(prompt_bufnr)

    if #picker:get_multi_selection() > 0 then
      for _, item in ipairs(picker:get_multi_selection()) do
        table.insert(selection, item[1])
      end
    else
      table.insert(selection, actions_state.get_selected_entry()[1])
    end

    print(vim.inspect(selection))

    p4_util.run_command(p4_commands.revert_file(selection))
  end

  local function shelve_files(prompt_bufnr)
  end

  local function unshelve_files(prompt_bufnr)
  end

  local function attach_mappings(prompt_bufnr, map)
    actions.select_default:replace(function()
      actions.close(prompt_bufnr)
      local entry = actions_state.get_selected_entry()

      if not entry then
        telescope_p4_pickers_util.warn_no_selection_action()
        return
      end
    end)
    map({ "i", "n" }, telescope_p4_config.opts.change_list.mappings.diff, diff_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_list.mappings.revert, revert_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_list.mappings.shelve, shelve_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_list.mappings.unshelve, unshelve_files)
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