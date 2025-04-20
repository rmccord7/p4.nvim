local M = {}

function M.get_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ "CL", help = "CL commands." })
  local sub_parser = parser:add_subparsers({ destination = "commands" })

  require("p4.commands.cl.new").add_parser(sub_parser)
end

return M

