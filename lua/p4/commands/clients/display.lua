M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="display", help = "Displays the P4 clients for the specified user." })

  parser:set_execute(function()
    local telescope_clients_api = require("p4.api.telescope.clients")

    telescope_clients_api.display()
  end)
end

return M
