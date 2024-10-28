local file_cmds = require("p4.api.commands.file")

vim.api.nvim_create_user_command(
    "P4add",
    function()
        file_cmds.add(vim.fn.expand("%:p"))
    end,
    {
        desc = "Adds a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4edit",
    function()
        file_cmds.edit(vim.fn.expand("%:p"))
    end,
    {
        desc = "Checks out a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4revert",
    function()
        file_cmds.revert(vim.fn.expand("%:p"))
    end,
    {
        desc = "Reverts a file"
    }
)

