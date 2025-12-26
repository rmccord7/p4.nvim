local M = {}

function M.add_parser(parent_subparser)

  local add_parser = parent_subparser:add_parser({ name="add", help = "Open the current buffer for add." })

  add_parser:set_execute(function()
    local file_api = require("p4.api.file")

    local success = file_api.add(vim.fn.expand("%:p"))

    if success then
      vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
      vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
    end
  end)
end

return M
