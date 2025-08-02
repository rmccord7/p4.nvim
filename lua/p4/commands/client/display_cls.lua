local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="display_cls", help = "Display P4 CLs for the specified P4 client." })

  parser:set_execute(function()
    local telescope_client_api = require("p4.api.telescope.client")

    telescope_client_api.display_client_cls()
  end)
end

return M
