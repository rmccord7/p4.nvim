M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="new", help = "Creates a new P4 client." })

  parser:set_execute(function()
    local client_api = require("p4.api.client")

    client_api.new()
  end)
end

return M
