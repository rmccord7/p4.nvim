# 🚦 P4.nvim

This plugin is still in development.

---

# 🚦 P4.nvim

Basic support for perforce in neovim.

## ✨ Features

- TODO

## ⚡️ Requirements

- Neovim >= 0.10.0
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
 'rmccord7/p4.nvim',
 dependencies = {'nvim-telescope/telescope.nvim'},
 opts = {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
 },
}
```

## ⚙️ Configuration

### Setup

Trouble comes with the following defaults:

```lua
{
  p4 = { -- P4 config.
      config = os.getenv('P4CONFIG') or "", -- Workspace P4CONFIG file name
  },
  clients = {
    cache = true, -- Cache P4USER clients
    frequency = 60000, -- Time to cache P4USER clients (ms)
    notify = true, -- Notify user once P4USER clients cached
  },
  telescope = { -- Telescope options
    clients = { -- P4 client picker options.
      filter_current_host = true, -- Filters P4 clients for the current host.
      mappings = { -- P4 client picker mappings.
        edit_spec = "<C-e>", -- Edit the selected P4 client's spec.
        display_change_lists = "<CR>", -- Displays the selected P4 client's change lists.
        delete_client = "<C-d>",-- Deletes the selected P4 client.
        change_workspace = "<C-w>", -- Changes the CWD to the selected P4 client's root.
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
```

## 🚀 Usage

### Commands

P4.nvim comes with the following commands:

- `P4add`: Opens the current file for add
- `P4edit`: Opens the current file for edit
- `P4revert`: Reverts the current file

Example keybindings:

```lua
-- Lua
vim.keymap.set("n", "<leader>pa", function() require("p4.nvim").P4add() end)
vim.keymap.set("n", "<leader>pe", function() require("p4.nvim").P4edit() end)
vim.keymap.set("n", "<leader>pr", function() require("p4.nvim").P4revert() end)
```

### Telescope

You can easily open any search results in **P4**, by defining a custom action:

```lua
local actions = require("telescope.actions")

-- Open all or selected files for add.
local p4_add = require("p4.telescope").add

-- Open all or selected files for edit.
local p4_edit = require("p4.telescope").edit

-- Revert all or selected files that are opened for add/edit.
local p4_revert = require("p4.telescope").revert

-- Get file information.
local p4_fstat = require("p4.telescope").fstat

local telescope = require("telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = {
          ["<c-a>"] = p4_add,
          ["<c-e>"] = p4_edit,
          ["<c-r>"] = p4_revert,
          ["<c-g>"] = p4_fstat,
      },
      n = {
          ["<c-a>"] = p4_add,
          ["<c-e>"] = p4_edit,
          ["<c-r>"] = p4_revert,
          ["<c-g>"] = p4_fstat,
      },
    },
  },
})
```
