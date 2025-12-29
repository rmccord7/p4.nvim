local M = {}

function M.add_parser(parent_subparser)

  local revert_parser = parent_subparser:add_parser({ name="revert", help = "Revert the current buffer." })

  revert_parser:set_execute(function()
    local file_api = require("p4.api.file")

    local success = file_api.revert(vim.fn.expand("%:p"))

    if success then
      vim.cmd("e!")
    end
  end)
end

return M
