local p4c_file = require("p4.core.file")

vim.api.nvim_create_user_command(
    "P4add",
    function()
        p4c_file.add()
    end,
    {
        desc = "Adds a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4edit",
    function()
        p4c_file.edit()
    end,
    {
        desc = "Checks out a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4revert",
    function()
        p4c_file.revert()
    end,
    {
        desc = "Reverts a file"
    }
)

