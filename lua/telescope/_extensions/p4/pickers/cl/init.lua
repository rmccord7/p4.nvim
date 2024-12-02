local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_CL_Picker
local P4_Telescope_CL_Picker = {}

--- Telescope picker to display the list of P4 CLs.
---
--- @param prompt_title string Telescope prompt title.
--- @param p4_cl_list P4_CL[] File list.
--- @param opts table? Telescope picker options.
function P4_Telescope_CL_Picker.load(prompt_title, p4_cl_list, opts)
  opts = opts or {}

  log.trace("Telescope_CL_Picker: picker")

  --- Processes results from the finder.
  ---
  --- @param entry P4_CL P4 CL.
  local function entry_maker(entry)

    local displayer = entry_display.create({
      separator = ': ',
      items = {
        { width = 8 },
        { remaining = true },
      },
    })

    --- @diagnostic disable-next-line Ignore redefined entry.
    local make_display = function(_entry)

      --- @type P4_CL
      local p4_cl = _entry.value

      return displayer {
        p4_cl:get().name,
        p4_cl:get_formatted_description(),
      }
    end

    return {
      value = entry,
      ordinal = entry:get().name,
      display = make_display,
    }
  end

  --- Controls what is displayed for each entry's preview.
  local function previewer()

    return previewers.new_buffer_previewer({
      title = "Change List Spec",
      get_buffer_by_name = function(_, entry)

        --- @type P4_CL
        local p4_cl = entry.value

        return p4_cl:get().name
      end,

      define_preview = function(self, entry)

        --- @type P4_CL
        local p4_cl = entry.value

        -- If we already have the spec, then load it into the
        -- buffer. Otherwise we need to query it.
        local spec = p4_cl:get_spec()

        --FIX: Need actual change output not description

        if spec then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(spec.description, '\n'))
        else
          local utils = require("telescope.previewers.utils")

          utils.job_maker({"p4", "change", "-o", p4_cl:get().name}, self.state.bufnr, {
            value = p4_cl:get().name,
            bufname = self.state.bufname,
          })
        end
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

        -- Use the last preview buffer since it displayed the P4 change
        -- list spec.
        local state = require("telescope.state")

        local bufnr = state.get_global_key("last_preview_bufnr")

        if bufnr then
          --- @type P4_CL
          local p4_cl = entry.value

          p4_cl:write_spec(bufnr)
        end
      else
        notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
      end
    end)

    local p4_config = require("p4.config")

    local cl_mappings = p4_config.opts.telescope.cl.mappings
    local cl_actions  = require("telescope._extensions.p4.pickers.cl.actions")

    map({ "n" }, cl_mappings.display_files, cl_actions.display_cl_files)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "P4 " .. prompt_title .. " CLs",
      results_title = "CLs",
      finder = finders.new_table({
        results = p4_cl_list,
        entry_maker = entry_maker,
      }),
      sorter = config.generic_sorter(opts),
      previewer = previewer(),
      attach_mappings = attach_mappings,
    })
    :find()
end

return P4_Telescope_CL_Picker
