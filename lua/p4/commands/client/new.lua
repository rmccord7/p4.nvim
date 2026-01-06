local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="new", help = "Creates a new P4 client." })

  parser:set_execute(function()
    local client_api = require("p4.api.client")

    --FIX: client name
    local success = client_api.new()

    if not success then
      notify(string.format("%s ", parser:get_names().name) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
