local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local notify = require("p4.notify")

--- @class P4_Telescope_File_Picker
local P4_Telescope_File_Picker = {}

--- Telescope picker to display the list of P4 files.
---
--- @param prompt_title string Telescope prompt title.
--- @param p4_file_list P4_File_List File list.
--- @param opts table? Telescope picker options.
function P4_Telescope_File_Picker.file_picker(prompt_title, p4_file_list, opts)
  opts = opts or {}

  if vim.tbl_isempty(p4_file_list:get()) then
    notify("No files to display in pickker", vim.log.levels.ERROR)
    return
  end

  --- Processes results from the finder.
  ---
  --- @param entry P4_File P4 File
  local function entry_maker(entry)

    return {
      value = entry,
      ordinal = entry.fstat.clientFile,
      filename = entry.fstat.clientFile,
      display = entry.fstat.clientFile .. " (" .. entry.fstat.change .. ")",
    }
  end

  --- Defines mappings.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  --- @param map function Maps keys to functions.
  ---
  local function attach_mappings(prompt_bufnr, map)

    -- local cl_mappings = require("p4_config.opts.telescope.change_lists.mappings")
    -- local cl_actions = require("telescope._extensions.p4.pickers.cl.actions")
    --
    -- map({ "i", "n" }, cl_mappings.diff, cl_actions.diff_files)
    -- map({ "i", "n" }, cl_mappings.revert, cl_actions.revert_files)
    -- map({ "i", "n" }, cl_mappings.shelve, cl_actions.shelve_files)
    -- map({ "i", "n" }, cl_mappings.unshelve, cl_actions.unshelve_files)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "P4 " .. prompt_title .. " Files",
      results_title = "Files",
      finder = finders.new_table({
        results = p4_file_list:get(),
        entry_maker = entry_maker,
      }),
      sorter = config.generic_sorter(opts),
      previewer = config.file_previewer(opts),
      attach_mappings = attach_mappings,
    })
    :find()
end

return P4_Telescope_File_Picker
