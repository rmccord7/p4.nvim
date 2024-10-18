local api = require("p4.api")

local function P4Log()
    local log = require("p4.core.log")
    vim.cmd(([[tabnew %s]]):format(log.outfile))
end

local function P4CLog()
    local log = require("p4.core.shell_log")
    vim.cmd(([[tabnew %s]]):format(log.outfile))
end

vim.api.nvim_create_user_command(
    "P4add",
    function()
        api.file.add(vim.fn.expand("%:p"))
    end,
    {
        desc = "Adds a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4edit",
    function()
        api.file.edit(vim.fn.expand("%:p"))
    end,
    {
        desc = "Checks out a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4revert",
    function()
        api.file.revert(vim.fn.expand("%:p"))
    end,
    {
        desc = "Reverts a file"
    }
)

vim.api.nvim_create_user_command(
  "P4Log",
  P4Log,
  {
    desc = "Opens the p4.nvim log.",
  }
)

vim.api.nvim_create_user_command(
  "P4CLog",
  P4CLog,
  {
    desc = "Opens the p4 command log.",
  }
)
