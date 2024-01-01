local config = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local telescope_p4_config = require("telescope._extensions.p4.config")
local telescope_p4_pickers_util = require("telescope._extensions.p4.pickers.util")

local p4 = require("p4")
local p4_commands = require("p4.commands")
local p4_util = require("p4.util")

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

  -- Make sure the P4 workspace is valid and we are logged into
  -- to the P4 server.
  if not telescope_p4_pickers_util.verify_p4_picker() then
    return
  end

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
    chunks = {}
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
    client = client or p4.p4.client

    return finders.new_oneshot_job(p4_commands.read_change_lists(client), {
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
        putils.job_maker(p4_commands.read_change_list(entry.name), self.state.bufnr, {
          value = entry.value,
          bufname = self.state.bufname,
        })
      end,
      keep_last_buf = true,
    })
  end

  --- Action to display change list files.
  local function display_change_list_files(prompt_bufnr)
    actions.close(prompt_bufnr)

    local entry = actions_state.get_selected_entry()

    result = p4_util.run_command(p4_commands.read_change_list_files(entry.name))

    if result.code == 0 then
      local files = {}

      for index, line in ipairs(vim.split(result.stdout, "\n")) do
        if line:find("#", 1, true) then
          local depot_file = line:sub(1, line:find("#", 1, true) - 1)

          result = p4_util.run_command(p4_commands.where_file(depot_file))

          if result.code == 0 then
            local path = {}
            for string in result.stdout:gmatch("%S+") do
              table.insert(path, string)
            end

            table.insert(files, index, path[3])
          end
        end
      end

      require("telescope._extensions.p4.pickers.cl").files_picker(files, {cl = entry.name})
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

      -- If an entry is selected, then we will open a temporary buffer
      -- to hold the P4 change list spec. The P4 change list spec will
      -- be written to the P4 server when written.
      if entry then

        -- Use the last preview buffer since it displayed the P4 change
        -- list spec.
        local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

        if bufnr then

          vim.api.nvim_set_option_value("buftype", "acwrite", { buf = bufnr })
          vim.api.nvim_set_option_value("filetype", "conf", { buf = bufnr })
          vim.api.nvim_set_option_value("expandtab", false, { buf = bufnr })

          vim.api.nvim_buf_set_name(bufnr, "change list: " .. entry.name)

          vim.api.nvim_win_set_buf(0, bufnr)

          vim.api.nvim_create_autocmd("BufWriteCmd", {
            buffer = bufnr,
            once = true,
            callback = function()
              local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

              result = vim.system(p4_commands.write_change_list(entry.name), { stdin = content }):wait()

              if result.code > 0 then
                p4_util.error(result.stderr)
                return
              end

              vim.api.nvim_buf_delete(bufnr, { force = true })
            end,
          })
        end

      else

        -- In case the user didn't select one or more entries before
        -- performing an action.
        telescope_p4_pickers_util.warn_no_selection_action()
        return
      end
    end)

    map({ "i", "n" }, telescope_p4_config.opts.change_lists.mappings.display_files, display_change_list_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_lists.mappings.display_shelved_files, display_change_list_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_lists.mappings.delete, display_change_list_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_lists.mappings.revert, display_change_list_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_lists.mappings.shelve, display_change_list_files)
    map({ "i", "n" }, telescope_p4_config.opts.change_lists.mappings.unshelve, display_change_list_files)

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
