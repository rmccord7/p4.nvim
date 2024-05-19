local config = require("p4.config")

local M = {}

-- M.extension_name = "Telescope P4"
-- M.namespace = vim.api.nvim_create_namespace("TelescopeP4")
--
-- --- Export default options
-- ---
-- ---@class TelescopeP4Options
-- ---@field clients? table
-- ---@field change_lists? table
-- ---@field change_list? table
-- M.defaults = {
--   clients = { -- P4 client picker options.
--     filter_current_host = true, -- Filters P4 clients for the current host.
--     mappings = { -- P4 client picker mappings.
--       edit_spec = "<C-e>", -- Edit the selected P4 client's spec.
--       display_change_lists = "<CR>", -- Displays the selected P4 client's change lists.
--       delete_client = "<C-d>",-- Deletes the selected P4 client.
--       change_workspace = "<C-w>", -- Changes the CWD to the selected P4 client's root.
--     },
--   },
--   change_lists = { -- P4 change lists picker options
--       mappings = { -- P4 change lists picker mappings.
--         edit_spec = "<C-e>", -- Edit the selected P4 change list's spec.
--         display_files = "<CR>", -- Display the selected P4 change list's files.
--         display_shelved_files = "<C-F>", -- Display the selected P4 change list's shelved files.
--         delete = "<C-d>", -- Deletes the selected P4 change list.
--         revert = "<C-r>", -- Reverts all files for the selected P4 change list.
--         shelve = "<C-s>", -- Shelves all files for the selected P4 change list.
--         unshelve = "<C-u>", -- Un-shelves all files for the selected P4 change list.
--       },
--   },
--   change_list = { -- P4 change list picker options
--     mappings = { -- P4 change list picker mappings.
--       open = "<CR>", -- Opens the selected files.
--       diff = "C-d", -- Diffs the selected file against the head revision.
--       revert = "<C-r>", -- Reverts the selected files.
--       shelve = "<C-s>", -- Shelves the selected files.
--       unshelve = "<C-u>", -- Un-shelves the selected files.
--     },
--   },
-- }
--
-- ---@type TelescopeP4Options
-- ---
-- M.opts = {}
-- ---@return TelescopeP4Options
--
-- --- Initializes the telescope extension.
-- ---
-- --- @param user_opts table? Optional parameters. Not used.
-- ---
-- function M.setup(opts)
--   user_opts = user_opts or {}
--
--   -- if user_opts.theme and string.len(user_opts.theme) > 0 then
--   --
--   --   if not themes["get_" .. user_opts.theme] then
--   --
--   --     vim.notify(
--   --       string.format("Could not apply provided telescope theme: '%s'", user_opts.theme),
--   --       vim.log.levels.WARN,
--   --       { title = M.extension_name }
--   --     )
--   --   else
--   --
--   --     user_opts = themes["get_" .. user_opts.theme](user_opts)
--   --
--   --   end
--   -- end
--
--   M.opts = vim.tbl_deep_extend("force", M.defaults, user_opts)
--
-- end

return M
