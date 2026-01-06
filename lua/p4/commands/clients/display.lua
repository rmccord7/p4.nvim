local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="display", help = "Displays the P4 clients for the specified user." })

  parser:set_execute(function()
    local telescope_clients_api = require("p4.api.telescope.clients")

    local success = telescope_clients_api.display()

    if not success then
      notify(string.format("%s ", parser:get_names().name) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
