local api = require("p4.api")

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

