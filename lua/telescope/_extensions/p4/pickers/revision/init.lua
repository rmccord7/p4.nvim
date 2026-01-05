local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Revision_Picker
local P4_Telescope_Revision_Picker = {}

--- Telescope picker to display the list of P4 CLs.
---
--- @param prompt_title string Telescope prompt title.
--- @param revision_list P4_Revision[] File list.
--- @param opts table? Telescope picker options.
function P4_Telescope_Revision_Picker.load(prompt_title, revision_list, opts)
  opts = opts or {}

  log.trace("Telescope_Revision_Picker: picker")

  --- Processes results from the finder.
  ---
  --- @param entry P4_Revision P4 Revision.
  local function entry_maker(entry)

    local displayer = entry_display.create({
      separator = " ",
      items = {
        { remaining = true },
        { remaining = true },
        { remaining = true },
        { remaining = true },
        { remaining = true },
      },
    })

    local make_display = function(_entry)

      --- @type P4_Revision
      local p4_revision = _entry.value

      return displayer {
        p4_revision.index .. ":",
        p4_revision.action,
        p4_revision.change,
        p4_revision.user,
        vim.fn.strftime("%m-%d-%y %I:%M %p", tonumber(p4_revision.time)),
      }
    end

    return {
      value = entry,
      ordinal = entry.index,
      display = make_display,
    }
  end

  --- Controls what is displayed for each entry's preview.
  local function previewer()

    return previewers.new_buffer_previewer({
      title = "CL Description",
      get_buffer_by_name = function(_, entry)

        --- @type P4_Revision
        local p4_revision = entry.value

        return p4_revision.change
      end,

      define_preview = function(self, entry)

        --- @type P4_Revision
        local p4_revision = entry.value

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(p4_revision.description, '\n'))
      end,
      keep_last_buf = true,
    })
  end

  --- Defines mappings.
  ---
  --- @param prompt_bufnr integer Identifies the telescope prompt buffer.
  ---
  --- @param map function Maps keys to functions.
  ---
  local function attach_mappings(prompt_bufnr, map)

    actions.select_default:replace(function()

      actions.close(prompt_bufnr)

      local entry = actions_state.get_selected_entry()

      if entry then
        notify("Not supported", vim.log.level.ERROR);
      else
        notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
      end
    end)

    local p4_config = require("p4.config")

    local revision_mappings = p4_config.opts.telescope.revision.mappings
    local revision_actions  = require("telescope._extensions.p4.pickers.revision.actions")

    map({ "n" }, revision_mappings.diff_against_workspace_file, revision_actions.diff_against_workspace_file)
    map({ "n" }, revision_mappings.diff_against_head_revision, revision_actions.diff_against_head_revision)
    map({ "n" }, revision_mappings.diff_against_prev_revision, revision_actions.diff_against_previous_revision)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "P4 " .. prompt_title .. " Revisions",
      results_title = "Revisions",
      finder = finders.new_table({
        results = revision_list,
        entry_maker = entry_maker,
      }),
      sorter = config.generic_sorter(opts),
      previewer = previewer(),
      attach_mappings = attach_mappings,
    })
    :find()
end

return P4_Telescope_Revision_Picker

