local M = {}

M.namespace = vim.api.nvim_create_namespace("P4")

---@class P4Options
---@field p4? table

--- Default options
local defaults = {
  log_level = vim.log.levels.DEBUG, -- Default log level for plugin
  p4 = { -- P4 config.
      config = os.getenv('P4CONFIG') or "", -- Workspace P4CONFIG file name
  },
  telescope = { -- Telescope options
    clients = { -- P4 client picker options.
      filter_current_host = true, -- Filters P4 clients for the current host.
      mappings = { -- P4 client picker mappings.
        edit_spec = "<C-e>", -- Edit the selected P4 client's spec.
        display_change_lists = "<CR>", -- Displays the selected P4 client's change lists.
        delete = "<C-d>",-- Deletes the selected P4 client.
        select = "<C-w>", -- Changes the CWD to the selected P4 client's root.
      },
    },
    change_lists = { -- P4 change lists picker options
        mappings = { -- P4 change lists picker mappings.
          edit_spec = "<C-e>", -- Edit the selected P4 change list's spec.
          display_files = "<CR>", -- Display the selected P4 change list's files.
          display_shelved_files = "<C-F>", -- Display the selected P4 change list's shelved files.
          delete = "<C-d>", -- Deletes the selected P4 change list.
          revert = "<C-r>", -- Reverts all files for the selected P4 change list.
          shelve = "<C-s>", -- Shelves all files for the selected P4 change list.
          unshelve = "<C-u>", -- Un-shelves all files for the selected P4 change list.
        },
    },
    change_list = { -- P4 change list picker options
      mappings = { -- P4 change list picker mappings.
        open = "<CR>", -- Opens the selected files.
        diff = "C-d", -- Diffs the selected file against the head revision.
        revert = "<C-r>", -- Reverts the selected files.
        shelve = "<C-s>", -- Shelves the selected files.
        unshelve = "<C-u>", -- Un-shelves the selected files.
      },
    },
  }
}

---@type P4Options
M.opts = {}

if vim.g.p4 and vim.g.p4.opts then
  M.opts = vim.tbl_deep_extend("force", {}, defaults, vim.g.p4.opts or {})
end

--- Lets user update default options
---
--- @param opts table? Optional parameters. Not used.
---
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return M
