local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="revert", help = "Revert the current buffer." })

  parser:set_execute(function()
    local file_api = require("p4.api.file")

    local file = vim.fn.expand("%:p")

    local success = file_api.revert(file)

    if success then
      vim.cmd("e!")
    else
      notify(string.format("%s ", parser:get_names()) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
