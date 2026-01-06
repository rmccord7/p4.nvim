local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="history", help = "Displays the P4 file history for the specified file." })

  parser:set_execute(function()
    local telescope_file_api = require("p4.api.telescope.history")

    local file = vim.fn.expand("%:p")

    local success = telescope_file_api.display(file)

    if not success then
      notify(string.format("%s ", parser:get_names().name) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
