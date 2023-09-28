
vim.api.nvim_create_user_command(
    "P4add",
    function()
        require("p4").add()
    end,
    {
        desc = "Adds a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4edit",
    function()
        require("p4").edit()
    end,
    {
        desc = "Checks out a file to the default changelist"
    }
)

vim.api.nvim_create_user_command(
    "P4revert",
    function()
        require("p4").revert()
    end,
    {
        desc = "Reverts a file"
    }
)
