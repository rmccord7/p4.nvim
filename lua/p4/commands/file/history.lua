local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="history", help = "Displays the P4 file history for the specified file." })

  parser:set_execute(function()
    local telescope_file_api = require("p4.api.telescope.history")

    telescope_file_api.display({vim.fn.expand("%:p")})
  end)
end

return M
