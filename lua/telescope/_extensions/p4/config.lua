-- local themes = require("telescope.themes")

local M = {}

M.extension_name = "Telescope P4"

M.defaults = {
  clients = {
    filter_current_host = true,
    mappings = {
      edit_spec = "<C-e>",
      display_change_lists = "<CR>",
      delete_client = "<C-d>",
      change_workspace = "<C-w>",
    },
  },
  change_lists = {
      mappings = {
        edit_spec = "<C-e>",
        display_files = "<CR>",
        display_shelved_files = "<C-F>",
        delete = "<C-d>",
        revert = "<C-r>",
        shelve = "<C-s>",
        unshelve = "<C-u>",
      },
  },
  change_list = {
    mappings = {
      open = "<CR>",
      diff = "C-d",
      revert = "<C-r>",
      shelve = "<C-s>",
      unshelve = "<C-u>",
    },
  },
}

M.opts = {}

function M.setup(user_opts)
  user_opts = user_opts or {}

  -- if user_opts.theme and string.len(user_opts.theme) > 0 then
  --
  --   if not themes["get_" .. user_opts.theme] then
  --
  --     vim.notify(
  --       string.format("Could not apply provided telescope theme: '%s'", user_opts.theme),
  --       vim.log.levels.WARN,
  --       { title = M.extension_name }
  --     )
  --   else
  --
  --     user_opts = themes["get_" .. user_opts.theme](user_opts)
  --
  --   end
  -- end

  M.opts = vim.tbl_deep_extend("force", M.defaults, user_opts)
end

return M
