local config = {}

config.namespace = vim.api.nvim_create_namespace("P4")

---@class P4_Config_Options : table
---@field config string Indicates the name of the P4CONFIG file

---@class P4_Telescope_Client_Options : table
---@field file_current_host boolean Indicates whether P4 clients are filtered for the current host when queried
---@field mappings P4_Telescope_Client_Mapping_Options Key mappings for telescope client picker

---@class P4_Telescope_Client_Mapping_Options : table
---@field edit_spec string Key mapping to edit the selected client's spec
---@field display_cls string Key mapping to query and display the selected client's CLs
---@field delete string Key mapping to delete the selected client
---@field select string Key mapping to set the selected client as the plugin's selected client

---@class P4_Telescope_CL_Options : table
---@field mappings P4_Telescope_CL_Mapping_Options Key mappings for telescope file picker

---@class P4_Telescope_CL_Mapping_Options : table
---@field edit_spec string Key mapping to edit the selected CL's spec
---@field display_files string Key mapping to query and display the selected CL's files
---@field display_shelved_files string Key mapping to query and display the selected CL's shelved files
---@field delete string Key mapping to delete the selected CL
---@field revert string Key mapping to revert the selected CL's files
---@field shelve string Key mapping to shelve the selected CL's files
---@field unshelve string Key mapping to unshelve the selected CL's files

---@class P4_Telescope_File_Options : table
---@field mappings P4_Telescope_File_Mapping_Options Key mappings for telescope file picker

---@class P4_Telescope_File_Mapping_Options : table
---@field open string Key mapping to open the selected files in their own buffer
---@field diff string Key mapping to diff the selected files against their head revisions
---@field revert string Key mapping to revert the selected files from their CL
---@field shelve string Key mapping to shelve the selected files from their CL
---@field unshelve string Key mapping to unshelve the selected files from their CL

---@class P4_Telescope_Options : table
---@field client P4_Telescope_Client_Options Client options.
---@field cl P4_Telescope_CL_Options CL options.
---@field file P4_Telescope_File_Options CL options.

---@class P4_Options : table
---@field log_level integer Indicates the level of logging
---@field p4 P4_Config_Options P4 config options
---@field telescope table P4 telescope options

--- Default options
---@type P4_Options
local defaults = {
  log_level = vim.log.levels.TRACE, -- Default log level for plugin
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
        open = "<c-o>", -- Opens the picker's selected file in a buffer.
        diff = "<c-d>", -- Diffs the selected file against the head revision.
        history = "<c-h>", -- Opens a file history picker to view the selected file's history.
        move = "<c-m>", -- Moves all selected files from one CL to another.
        revert = "<c-R>", -- Reverts the selected files.
        shelve = "<c-s>", -- Shelves all selected files..
        unshelve = "<c-u>", -- Un-shelves all selected files.
      },
    },
  }
}

if vim.g.p4 and vim.g.p4.opts then
  config.opts = vim.tbl_deep_extend("force", {}, defaults, vim.g.p4.opts or {})
end

--- Lets user update default options
---
--- @param opts table? Optional parameters. Not used.
---
function config.setup(opts)
  config.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

return config
