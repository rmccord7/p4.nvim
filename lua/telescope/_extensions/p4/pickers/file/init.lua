local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
-- local actions = require("telescope.actions")
local utils = require("telescope.utils")

local entry_display = require("telescope.pickers.entry_display")

local notify = require("p4.notify")

--- @class P4_Telescope_File_Picker
local P4_Telescope_File_Picker = {}

--- Telescope picker to display the list of P4 files.
---
--- @param prompt_title string Telescope prompt title.
--- @param p4_file_list P4_File_List File list.
--- @param opts table? Telescope picker options.
function P4_Telescope_File_Picker.load(prompt_title, p4_file_list, opts)
  opts = opts or {}

  if vim.tbl_isempty(p4_file_list:get().files) then
    notify("No files to display in picker", vim.log.levels.ERROR)
    return
  end

  --- Processes results from the finder.
  ---
  --- @param entry P4_File P4 File
  local function entry_maker(entry)

    local file_stats = entry:get_file_stats()

    assert(file_stats, "File stats have not been read")

    local hl_group, icon
    local display, _ = utils.transform_path(opts, file_stats.clientFile)
    _, hl_group, icon = utils.transform_devicons(file_stats.clientFile, display, opts.disable_devicons)

    local displayer = entry_display.create {
      separator = "",
      items = {
        { width = #icon }, -- File icon
        { remaining = true }, -- File path
        { remaining = true }, -- File P4 CL
      },
    }

    --- @diagnostic disable-next-line Ignore redefined entry.
    local make_display = function(_entry)

      if hl_group then
        return displayer {
          {icon, hl_group},
          display,
          " (" .. file_stats.change .. ")",
        }
      else
        return displayer {
          icon,
          display,
          " (" .. file_stats.change .. ")",
        }
      end
    end

    return {
      value = entry,
      ordinal = file_stats.clientFile,
      filename = file_stats.clientFile,
      -- display = utils.transform_path(opts, (file_stats.clientFile)) .. " (" .. file_stats.change .. ")",
      display = make_display,
    }
  end

  --- Defines mappings.
  ---
  --- @param _ integer Prompt buffer number.
  ---
  --- @param map function Maps keys to functions.
  ---
  local function attach_mappings(_, map)

    -- actions.select_default:replace(function()
    --
    --   actions.close(prompt_bufnr)
    --
    --   local entry = actions_state.get_selected_entry()
    --
    --   if entry then
    --
    --     -- Use the last preview buffer since it displayed the P4 change
    --     -- list spec.
    --     local state = require("telescope.state")
    --
    --     local bufnr = state.get_global_key("last_preview_bufnr")
    --
    --     if bufnr then
    --       --- @type P4_CL
    --       local p4_cl = entry.value
    --
    --       p4_cl:write_spec(bufnr)
    --     end
    --   else
    --     notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
    --   end
    -- end)

    local p4_config = require("p4.config")
    local file_mappings = p4_config.opts.telescope.file.mappings
    local file_actions  = require("telescope._extensions.p4.pickers.file.actions")

    map({ "i", "n" }, file_mappings.open, file_actions.edit)
    map({ "i", "n" }, file_mappings.diff, file_actions.diff)
    map({ "i", "n" }, file_mappings.history, file_actions.history)
    map({ "i", "n" }, file_mappings.move, file_actions.move)
    map({ "i", "n" }, file_mappings.revert, file_actions.revert)
    map({ "i", "n" }, file_mappings.shelve, file_actions.shelve)
    map({ "i", "n" }, file_mappings.unshelve, file_actions.unshelve)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "P4 " .. prompt_title .. " Files",
      results_title = "Files",
      finder = finders.new_table({
        results = p4_file_list:get().files,
        entry_maker = entry_maker,
      }),
      sorter = config.generic_sorter(opts),
      previewer = config.file_previewer(opts),
      attach_mappings = attach_mappings,
    })
    :find()
end

return P4_Telescope_File_Picker
