local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local telescope_p4_config = require("telescope._extensions.p4.config")
local telescope_p4_pickers_util = require("telescope._extensions.p4.pickers.util")

local p4_commands = require("p4.commands")
local p4_util = require("p4.util")

local p4c_client = require("p4.core.client")

local M = {}

--- Telescope picker to display all of a user's P4 clients.
---
--- @param opts table? Optional parameters. Not used.
---
function M.picker(opts)
  opts = opts or {}

  -- Make sure the P4 workspace is valid and we are logged into
  -- to the P4 server.
  if not telescope_p4_pickers_util.verify_p4_picker() then
    return
  end

  --- Processes results from the finder.
  local function entry_maker(entry)
    chunks = {}
    for substring in entry:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    local client = chunks[2]

    -- Filter clients for the current host.
    if telescope_p4_config.opts.clients.filter_current_host then

      result = p4_util.run_command(p4_commands.read_client(client))

      if result.code == 0 then

        for _, line in ipairs(vim.split(result.stdout, "\n")) do
          if line:find("^Host") then

            chunks = {}
            for substring in line:gmatch("%S+") do
              table.insert(chunks, substring)
            end

            if chunks[2] ~= p4_config.opts.p4.host then
              return nil
            end
            break
          end
        end
      end
    end

    return {
      value = entry,
      name = client,
      ordinal = client,
      display = client,
    }
  end

  --- Issues shell command to read the P4 user's clients.
  local function finder()
    return finders.new_oneshot_job(p4_commands.read_clients(), {
      entry_maker = entry_maker,
    })
  end

  --- Controls what is displayed for each entry's preview.
  local function previewer()
    return previewers.new_buffer_previewer({
      title = "Client Spec",
      get_buffer_by_name = function(_, entry)
        return entry.value
      end,

      define_preview = function(self, entry)
        putils.job_maker(p4_commands.read_client(entry.name), self.state.bufnr, {
          value = entry.value,
          bufname = self.state.bufname,
        })
      end,
      keep_last_buf = true,
    })
  end

  --- Action to edit the P4 client spec.
  local function edit_client_spec(prompt_bufnr)
    actions.close(prompt_bufnr)

    local entry = actions_state.get_selected_entry()

    if entry then

      local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

      if bufnr then
        p4c_client.edit_spec(bufnr, entry.name)
      end

    else
      telescope_p4_pickers_util.warn_no_selection_action()
    end
  end

  --- Defines mappings.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
  --- @param map function Maps keys to functions.
  ---
  local function attach_mappings(prompt_bufnr, map)

    actions.select_default:replace(function()

      -- Replace select default option.
      actions.close(prompt_bufnr)

      -- Get the selected entry.
      local entry = actions_state.get_selected_entry()

      -- In case the user didn't select one or more entries before
      -- performing an action.
      if not entry then
        telescope_p4_pickers_util.warn_no_selection_action()
        return
      end

      M.change_lists_picker(opts, entry.name)
    end)

    map({ "i", "n" }, telescope_p4_config.opts.clients.mappings.edit_spec, edit_client_spec)
    map({ "i", "n" }, telescope_p4_config.opts.clients.mappings.delete_client, edit_client_spec)
    map({ "i", "n" }, telescope_p4_config.opts.clients.mappings.change_workspace, edit_client_spec)

    return true
  end

  pickers
    .new(opts, {
      prompt_title = "Search Clients",
      results_title = "clients",
      finder = finder(),
      sorter = config.generic_sorter(opts),
      previewer = previewer(),
      attach_mappings = attach_mappings,
    })
    :find()
end

return M
