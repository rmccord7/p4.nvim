local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="diff", help = "Diffs the specified file against the head revision." })

  parser:set_execute(function()
    local file_api = require("p4.api.file")

    local file = vim.fn.expand("%:p")

    local success = file_api.diff(file)

    if not success then
      notify(string.format("%s ", parser:get_names()) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
