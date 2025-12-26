local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="diff", help = "Diffs the specified file against the head revision." })

  parser:set_execute(function()
    local file_api = require("p4.api.file")

    file_api.diff(vim.fn.expand("%:p"))
  end)
end

return M
