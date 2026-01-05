local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.get_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ "Client", help = "Client commands." })

  local sub_parser = parser:add_subparsers({ destination = "commands" })

  require("p4.commands.client.display_cls").add_parser(sub_parser)
end

return M

