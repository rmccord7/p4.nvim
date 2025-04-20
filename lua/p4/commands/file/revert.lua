local M = {}

function M.add_parser(parent_subparser)

  local revert_parser = parent_subparser:add_parser({ name="revert", help = "Revert the current buffer." })

  revert_parser:set_execute(function()
    local file_api = require("p4.api.file")

    file_api.revert({vim.fn.expand("%:p")})
  end)
end

return M
