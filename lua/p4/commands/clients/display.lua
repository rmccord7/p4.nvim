M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="display", help = "Displays the P4 clients for the specified user." })

  parser:set_execute(function()
    local client_api = require("p4.api.client")

    client_api.new()
  end)
end

return M
