local cmdparse = require("mega.cmdparse")

local _PREFIX = "P4"

---@type mega.cmdparse.ParserCreator
local _SUBCOMMANDS = function()
  ---@type mega.cmdparse.ParameterParser
  local parser = cmdparse.ParameterParser.new({ name = _PREFIX, help = "The root of all P4 commands." })

  ---@type mega.cmdparse.Subparsers
  local sub_parser = parser:add_subparsers({ destination = "commands" })

  require("p4.commands.file").get_parser(sub_parser)
  require("p4.commands.cl").get_parser(sub_parser)
  require("p4.commands.client").get_parser(sub_parser)
  require("p4.commands.clients").get_parser(sub_parser)

  require("p4.commands.opened").add_parser(sub_parser)
  require("p4.commands.log").add_parser(sub_parser)
  require("p4.commands.output").add_parser(sub_parser)

  return parser
end

cmdparse.create_user_command(_SUBCOMMANDS, _PREFIX)
