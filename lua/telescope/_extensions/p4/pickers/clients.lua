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

local M = {}

function M.picker(opts)
  opts = opts or {}

  if not telescope_p4_pickers_util.verify_p4_picker() then
    return
  end

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

  local function finder()
    return finders.new_oneshot_job(p4_commands.read_clients(), {
      entry_maker = entry_maker,
    })
  end

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

  local function edit_client_spec(prompt_bufnr)
    actions.close(prompt_bufnr)

    local entry = actions_state.get_selected_entry(prompt_bufnr)

    if entry then

      local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

      if bufnr then
        vim.api.nvim_set_option_value("buftype", "acwrite", { buf = bufnr })
        vim.api.nvim_set_option_value("filetype", "conf", { buf = bufnr })
        vim.api.nvim_set_option_value("expandtab", false, { buf = bufnr })

        vim.api.nvim_buf_set_name(bufnr, "Client: " .. entry.name)

        vim.api.nvim_win_set_buf(0, bufnr)

        vim.api.nvim_create_autocmd("BufWriteCmd", {
          buffer = bufnr,
          once = true,
          callback = function()
            local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            result = vim.system(p4_commands.write_client(entry.name), { stdin = content }):wait()

            if result.code > 0 then
              p4_util.error(result.stderr)
              return
            end

            vim.api.nvim_buf_delete(bufnr, { force = true })
          end,
        })
      end
    else
      telescope_p4_pickers_util.warn_no_selection_action()
    end
  end

  local function attach_mappings(prompt_bufnr, map)
    actions.select_default:replace(function()
      actions.close(prompt_bufnr)
      local entry = actions_state.get_selected_entry()

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
