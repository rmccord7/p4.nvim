local M = {}

function M.add_parser(parent_subparser)

  local edit_parser = parent_subparser:add_parser({ name="edit", help = "Open the current buffer for edit." })

  edit_parser:set_execute(function()
    local file_api = require("p4.api.file")

    file_api.edit({vim.fn.expand("%:p")})
  end)
end

return M
