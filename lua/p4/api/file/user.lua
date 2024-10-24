local file = require("p4.api.file")

vim.api.nvim_create_user_command(
    "P4add",
    function()
        file.add(vim.fn.expand("%:p"))
    end,
    {
        desc = "Adds a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4edit",
    function()
        file.edit(vim.fn.expand("%:p"))
    end,
    {
        desc = "Checks out a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4revert",
    function()
        file.revert(vim.fn.expand("%:p"))
    end,
    {
        desc = "Reverts a file"
    }
)

