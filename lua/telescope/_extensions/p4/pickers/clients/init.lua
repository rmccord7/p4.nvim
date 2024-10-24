local config = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local p4_config = require("p4.config")

local p4_env = require("p4.core.env")
local p4_shell = require("p4.core.shell")

local p4_client_cmds = require("p4.core.commands.client")

local tp4_client = require("telescope._extensions.p4.pickers.client")
local tp4_util = require("telescope._extensions.p4.pickers.util")

local M = {}

--- Telescope picker to display all of a user's P4 clients.
---
--- @param opts table? Optional parameters. Not used.
---
function M.picker(opts)
  opts = opts or {}

  --- Processes results from the finder.
  local function entry_maker(entry)
    chunks = {}
    for substring in entry:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    local client = chunks[2]

    -- Filter clients for the current host.
    if p4_config.opts.telescope.clients.filter_current_host then

      result = p4_shell.run(p4_client_cmds.read_spec(client))

      if result.code == 0 then

        for _, line in ipairs(vim.split(result.stdout, "\n")) do
          if line:find("^Host") then

            chunks = {}
            for substring in line:gmatch("%S+") do
              table.insert(chunks, substring)
            end

            if chunks[2] ~= p4_env.host then
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
    return finders.new_oneshot_job(p4_client_cmds.read(), {
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
        putils.job_maker(p4_client_cmds.read_spec(entry.name), self.state.bufnr, {
          value = entry.value,
          bufname = self.state.bufname,
        })
      end,
      keep_last_buf = true,
    })
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
        tp4_util.warn_no_selection_action()
        return
      end

      tp4_client.pending_cl_picker(opts, entry.name)
    end)

    local clients_mappings = p4_config.opts.telescope.change_lists.mappings
    local clients_actions  = require("telescope._extensions.p4.pickers.clients.actions")

    map({ "i", "n" }, clients_mappings.edit_spec, clients_actions.edit_client_spec)
    map({ "i", "n" }, clients_mappings.delete, clients_actions.delete_client)
    map({ "i", "n" }, clients_mappings.selectc, clients_actions.select_client)

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
