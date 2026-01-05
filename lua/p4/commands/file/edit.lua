local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="edit", help = "Open the current buffer for edit." })

  parser:set_execute(function()
    local file_api = require("p4.api.file")

    local file = vim.fn.expand("%:p")

    local success = file_api.edit(file)

    if success then
      vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
      vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
    else
      notify(string.format("%s ", parser:get_names()) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
