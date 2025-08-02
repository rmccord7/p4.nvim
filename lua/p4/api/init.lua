local commands = require("p4.commands")

local p4_api = {
}

---@class P4Cmd
---@field impl fun(args:string[], opts: vim.api.keyset.user_command) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

---Register a `:P4` subcommand.
---@param name string The name of the subcommand to register
---@param cmd P4Cmd
function p4_api.register_p4_subcommand(name, cmd)
    commands.register_subcommand(name, cmd)
end

return p4_api
