# P4.nvim

This plugin is a learning experience and used for my business needs. It is still in development and may include broken changes.

---

# P4.nvim

Basic support for perforce in neovim.

## Features

- TODO

## Requirements

- Neovim >= 0.11.0
- [telescope](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-nio](https://github.com/nvim-neotest/nvim-nio)
- [mega.cmdparse](https://github.com/ColinKennedy/mega.cmdparse)

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'rmccord7/p4.nvim',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-telescope/telescope.nvim',
    {
      "ColinKennedy/mega.cmdparse",
      dependencies = { "ColinKennedy/mega.logging" },
      version = "v1.*",
    },
  },
}
```

## Configuration

### Setup

P4.nvim comes with the following defaults:

```lua
{
  p4 = { -- P4 config.
      config = os.getenv('P4CONFIG') or "", -- Workspace P4CONFIG file name
  },
  telescope = { -- Telescope options
    client = { -- P4 client picker options.
      filter_current_host = true, -- Filters P4 clients for the current host.
      mappings = { -- P4 client picker mappings.
        delete = "<c-D",-- Deletes the selected P4 client.
        display_cls = "<c-d>", -- Displays the selected P4 client's change lists.
        edit_spec = "<c-e>", -- Edit the selected P4 client's spec.
      },
    },
    cl = { -- P4 change list picker options
      mappings = { -- P4 change list picker mappings.
        delete = "<c-D>", -- Un-shelves the selected files.
        display_files = "<c-d>", -- Display the selected P4 change list's files.
        display_shelved_files = "<c-S>", -- Display the selected P4 change list's shelved files.
        edit_spec = "<c-e>", -- Edit the selected P4 change list's spec.
        revert = "<c-R>", -- Reverts the selected files.
        shelve = "<c-s>", -- Shelves the selected files.
        unshelve = "<c-u>", -- Un-shelves the selected files.
      },
    },
    file = { -- P4 file picker options
      mappings = { -- P4 change lists picker mappings.
        open = "<c-e>", -- Opens the file for edit.
        diff = "<c-d>", -- Diffs the selected file against the head revision.
        history = "<c-h>", -- Opens a file history picker to view the selected file's history.
        move = "<c-v>", -- Moves all selected files from one CL to another.
        revert = "<c-R>", -- Reverts the selected files.
        shelve = "<c-s>", -- Shelves all selected files..
        unshelve = "<c-u>", -- Un-shelves all selected files.
      },
    },
  }
}
```

## Usage

### Commands

P4.nvim comes with the following commands:

- `P4 file add`: Opens the current file for add.
- `P4 file edit`: Opens the current file for edit.
- `P4 file revert`: Reverts the current file.

- `P4 clients display`: Displays the user's P4 clients.

- `P4 client new`: Creates a new P4 client spec.
- `P4 client display_cls`: Displays the CL list for the current client.

- `P4 cl new`: Creates a new P4 CL spec.

- `P4 output`: View output from the P4 server.
- `P4 log`: View plugin logging.

- `P4 opened`: Display current files open in the worksapce.

Example keybindings:

```lua
-- Lua
vim.keymap.set("n", "<leader>po", [[:P4 opened<CR>]], {nowait = true})
```

### Telescope

P4 commands for telescope pickers.

```lua
local telescope = require("telescope")
local p4_telescope = require("p4.telescope")

telescope.setup({
  defaults = {
    mappings = {
      i = {
          ["<c-a>"] = p4_telescope.add, -- Open all or selected files for add.
          ["<c-e>"] = p4_telescope.edit, -- Open all or selected files for edit.
          ["<c-r>"] = p4_telescope.revert, -- Revert all or selected files that are opened for add/edit.
          ["<c-g>"] = p4_telescope.fstat, -- Get file information.
      },
      n = {
          ["<c-a>"] = p4_telescope.add, -- Open all or selected files for add.
          ["<c-e>"] = p4_telescope.edit, -- Open all or selected files for edit.
          ["<c-r>"] = p4_telescope.revert, -- Revert all or selected files that are opened for add/edit.
          ["<c-g>"] = p4_telescope.fstat, -- Get file information.
      },
    },
  },
})
```
