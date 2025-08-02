local M = {}

function M.add_parser(parent_subparser)

  local add_parser = parent_subparser:add_parser({ name="add", help = "Open the current buffer for add." })

  add_parser:set_execute(function()
    local file_api = require("p4.api.file")

    file_api.add({vim.fn.expand("%:p")})
  end)
end

return M
