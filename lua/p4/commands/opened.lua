local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="opened", help = "Display the files that are checked out in the current user's P4 client workspace." })

  parser:set_execute(function()
    local telescope_client_api = require("p4.api.telescope.client")

    telescope_client_api.display_opened_files()
  end)
end

return M
