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
    'nvim-neotest/nvim-nio', -- Used for async
    'nvim-telescope/telescope.nvim', -- Used for picker
    {
      "ColinKennedy/mega.cmdparse", -- Used for plugin command parsing
      dependencies = { "ColinKennedy/mega.logging" },
      version = "v1.*",
    },
  },
}
```

## Configuration

### Setup

P4.nvim can be configured with vim variables and does not require a function
call to initialize the plugin or configure the defaults.

P4.nvim needs information about the P4 environment in order to send commands to
the P4 server. The P4USER, P4HOST, P4PORT, and P4CLIENT are required and must
be specified using one of the three options below in order of highest to lowest
precedence:

1. Vim variables

    1. Using lazy spec

    Recommended to use project specific .lazy.lua spec for this case.

```lua
  -- Always executed for lazy spec.
  init = function(_)
    vim.g.p4.user = "User",
    vim.g.p4.host = "Host",
    vim.g.p4.port = "Port",
    vim.g.p4.client = "Client",
  end,
```

   2. Project file (see :help exrc).

2. P4CONFIG file at project root (Recommended)

P4CONFIG enviroment variable is expected to be set in this case so the plugin
knows the file name.

3. Shell environment

Something like dotenv to set the required environment variables.

P4.nvim comes with the following default options:

```lua
  -- Always executed for lazy spec.
  init = function(_)
    vim.g.p4.opts = {
      p4 = { -- P4 config.
          config = os.getenv('P4CONFIG') or "", -- Use enviroment or set explicity
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
  end,
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
local file_picker_actions = require("telescope._extensions.p4.pickers.file.actions")

telescope.setup({
  defaults = {
    mappings = {
      i = {
          ["<c-a>"] = file_picker_actions.add, -- Open all or selected files for add.
          ["<c-e>"] = file_picker_actions.edit, -- Open all or selected files for edit.
          ["<c-r>"] = file_picker_actions.revert, -- Revert all or selected files that are opened for add/edit.
          ["<c-g>"] = file_picker_actions.fstat, -- Get file information.
      },
      n = {
          ["<c-a>"] = file_picker_actions.add, -- Open all or selected files for add.
          ["<c-e>"] = file_picker_actions.edit, -- Open all or selected files for edit.
          ["<c-r>"] = file_picker_actions.revert, -- Revert all or selected files that are opened for add/edit.
          ["<c-g>"] = file_picker_actions.fstat, -- Get file information.
      },
    },
  },
})
```
