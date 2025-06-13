local M = {}

function M.get_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ "file", help = "File commands." })
  local sub_parser = parser:add_subparsers({ destination = "commands" })

  require("p4.commands.file.add").add_parser(sub_parser)
  require("p4.commands.file.edit").add_parser(sub_parser)
  require("p4.commands.file.revert").add_parser(sub_parser)
  require("p4.commands.file.history").add_parser(sub_parser)
end

return M

