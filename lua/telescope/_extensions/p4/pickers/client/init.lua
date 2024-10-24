local config = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local p4_config = require("p4.config")

local p4_env = require("p4.core.env")

local p4_cl_cmds = require("p4.commands.cl")

local p4_cl = require("p4.api.cl")

local tp4_util = require("telescope._extensions.p4.pickers.util")

local M = {}

--- Telescope picker to display all of a user's pending P4 change
--- lists.
---
--- @param opts table? Optional parameters. Not used.
---
--- @param client string P4 client.
---
function M.pending_cl_picker(opts, client)
  opts = opts or {}

  --- Helper function to format the result before it is
  --- displayed.
  local function displayer()
    local items = {
      { width = 9 },
    }

    return entry_display.create({
      separator = " ",
      items = items,
    })
  end

  --- Formats an entry before it is displayed in the results.
  local function make_display(entry)
    local display = {
      { entry.name },
    }

    return displayer()(display)
  end

  --- Processes results from the finder.
  local function entry_maker(entry)
    local chunks = {}
    for substring in entry:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    -- Second chunk contains the P4 change list number
    return {
      value = entry,
      name = chunks[2],
      ordinal = chunks[2],
      display = make_display,
    }
  end

  --- Issues shell command to read the P4 user's change lists.
  local function finder()
    client = client or p4_env.client

    -- Read pending change lists for the current user's specified
    -- P4 client.
    local read_opts = {
      client = client,
      pending = true,
    }

    return finders.new_oneshot_job(p4_cl_cmds.read(read_opts), {
      entry_maker = entry_maker,
    })
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
        putils.job_maker(p4_cl_cmds.read_spec(entry.name), self.state.bufnr, {
          value = entry.value,
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

      -- Replace select default option.
      actions.close(prompt_bufnr)

      -- Get the selected entry.
      local entry = actions_state.get_selected_entry()

      -- If an entry is selected, then we will open a temporary buffer
      -- to hold the P4 change list spec. The P4 change list spec will
      -- be written to the P4 server when written.
      if entry then

        -- Use the last preview buffer since it displayed the P4 change
        -- list spec.
        local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

        -- Entry name is CL number
        local cl = p4_cl.new(entry.name)

        if bufnr then
          cl:edit_spec(bufnr)
        end

      else

        -- In case the user didn't select one or more entries before
        -- performing an action.
        tp4_util.warn_no_selection_action()
        return
      end
    end)

    local client_mappings = p4_config.opts.telescope.change_lists.mappings
    local client_actions  = require("telescope._extensions.p4.pickers.client.actions")

    map({ "i", "n" }, client_mappings.display_files, client_actions.display_cl_files)
    map({ "i", "n" }, client_mappings.display_shelved_files, client_actions.display_shelved_cl_files)
    map({ "i", "n" }, client_mappings.delete, client_actions.delete_cl)
    map({ "i", "n" }, client_mappings.revert, client_actions.revert_cl)
    map({ "i", "n" }, client_mappings.shelve, client_actions.shelve_cl)
    map({ "i", "n" }, client_mappings.unshelve, client_actions.unshelve_cl)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "Search Pending Change Lists",
      results_title = "Pending Change Lists",
      finder = finder(),
      sorter = config.generic_sorter(opts),
      previewer = previewer(),
      attach_mappings = attach_mappings,
    })
    :find()
end

return M
