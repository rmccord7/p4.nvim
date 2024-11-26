local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Client_Picker
local P4_Telescope_Client_Picker = {}

--- Telescope picker to display all of a user's P4 clients.
---
--- @param prompt_title string Telescope prompt title.
--- @param p4_client_list P4_Client[] Client list.
--- @param opts table? Telescope picker options.
function P4_Telescope_Client_Picker.picker(prompt_title, p4_client_list, opts)
  opts = opts or {}

  log.trace("Telescope Clients Picker")

  --- Processes results from the finder.
  ---
  --- @param entry P4_Client P4 Client.
  local function entry_maker(entry)

    return {
      value = entry,
      ordinal = entry.name,
      display = entry.name,
    }
  end

  --- Controls what is displayed for each entry's preview.
  local function previewer()

    return previewers.new_buffer_previewer({
      title = "Change List Spec",
      get_buffer_by_name = function(_, entry)
        return entry.name
      end,

      define_preview = function(self, entry)

        --- Issues shell command to read an entries P4 change list spec
        --- into a buffer so it can be displayed as a preview.
        utils.job_maker({"p4", "client", "-o", entry.value.name}, self.state.bufnr, {
          value = entry.value.name,
          bufname = self.state.bufname,
        })
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
        local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

        if bufnr then
          --- @type P4_Client
          local p4_client = entry.value

          p4_client:write_spec(bufnr)
        end
      else
        notify("Please make a valid selection before performing the action.", vim.log.levels.WARN)
      end
    end)

    -- local p4_config = require("p4.config")
    --
    -- local cl_mappings = p4_config.opts.telescope.cl.mappings
    -- local cl_actions  = require("telescope._extensions.p4.pickers.cl.actions")
    --
    -- map({ "n" }, cl_mappings.display_files, cl_actions.display_cl_files)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "P4 " .. prompt_title .. " CLs",
      results_title = "Clients",
      finder = finders.new_table({
        results = p4_client_list,
        entry_maker = entry_maker,
      }),
      sorter = config.generic_sorter(opts),
      previewer = previewer(),
      attach_mappings = attach_mappings,
    })
    :find()
end

return P4_Telescope_Client_Picker
