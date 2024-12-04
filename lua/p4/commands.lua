local log = require("p4.log")
local notify = require("p4.notify")

local commands = {}

---@type { [string]: P4Cmd }
local p4_command_tbl = {

  -- Opens a file for add in the current client workspace.
  Add = {
    impl = function(_, _)
      local file_api = require("p4.api.file")

      file_api.add({vim.fn.expand("%:p")})
    end,
  },

  -- Opens a file for edit in the current client workspace.
  Edit = {
    impl = function(_, _)
      local file_api = require("p4.api.file")

      file_api.edit({vim.fn.expand("%:p")})
    end,
  },

  -- Reverts a file in the current client workspace.
  Revert = {
    impl = function(_, _)
      local file_api = require("p4.api.file")

      file_api.revert({vim.fn.expand("%:p")})
    end,
  },

  -- Creates a new CL in the current client workspace.
  New_CL = {
    impl = function(_, _)
      local cl_api = require("p4.api.cl")

      cl_api.new()
    end,
  },

  -- Creates a new client.
  New_Client = {
    impl = function(_, _)
      local client_api = require("p4.api.client")

      client_api.new()
    end,
  },

  -- Displays clients for the current user.
  Display_Clients = {
    impl = function(_, _)
      local telescope_clients_api = require("p4.api.telescope.clients")

      telescope_clients_api.display()
    end,
  },

  -- Displays CL's for the current client workspace.
  Display_CLs = {
    impl = function(_, _)
      local telescope_client_api = require("p4.api.telescope.client")

      telescope_client_api.display_client_cls()
    end,
  },

  -- Displays open files for the current client workspace.
  Display_Open_Files = {
    impl = function(_, _)
      local telescope_client_api = require("p4.api.telescope.client")

      telescope_client_api.display_opened_files()
    end,
  },

  -- Opens the P4 command log.
  Command_Log = {
    impl = function(_, _)
      local p4_log = require("p4.core.log")

      vim.cmd(([[tabnew %s]]):format(p4_log.outfile))
    end,
  },

  -- Opens the p4.nvim log.
  Log = {
    impl = function(_, _)
      vim.cmd(([[tabnew %s]]):format(log.outfile))
    end,
  },

  -- Opens the p4.nvim log.
  Test = {
    impl = function(_, _)
      vim.cmd(([[tabnew %s]]):format(log.outfile))
    end,
  },
}

local function p4_cmd(opts)
    local fargs = opts.fargs
    local cmd = fargs[1]
    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local command = p4_command_tbl[cmd]
    if not command then
        notify("Unknown command: " .. cmd, vim.log.levels.ERROR)
        return
    end
    command.impl(args, opts)
end

function commands.create_commands()
  log.trace("Creating commands")

  vim.api.nvim_create_user_command("P4", p4_cmd, {
    nargs = "+",
    desc = "Interacts with the P4 environment",
    complete = function(arg_lead, cmdline, _)

      -- Check if the sub-command has a completion.
      local sub_cmd_key, sub_cmd_arg_lead = cmdline:match("^['<,'>]*P4[!]*%s(%S+)%s(.*)$")
      if sub_cmd_key
          and sub_cmd_arg_lead
          and p4_command_tbl[sub_cmd_key]
          and p4_command_tbl[sub_cmd_key].complete
      then
          -- The sub_cmd has completions. Return them.
          return p4_command_tbl[sub_cmd_key].complete(sub_cmd_arg_lead)
      end

      -- Check if cmdline is a sub-command.
      if cmdline:match("^['<,'>]*P4[!]*%s+%w*$") then

        -- Filter sub commands that match.
        local sub_cmd_keys = vim.tbl_keys(p4_command_tbl)
        return vim.iter(sub_cmd_keys)
        :filter(function(key)
          return key:find(arg_lead) ~= nil
        end)
        :totable()
      end
    end,
    bang = true,
  })
end

return commands
