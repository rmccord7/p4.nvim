local notify = require("p4.notify")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="display_cls", help = "Display P4 CLs for the specified P4 client." })

  parser:set_execute(function()
    local telescope_client_api = require("p4.api.telescope.client")

    local success = telescope_client_api.display_client_cls()

    if not success then
      notify(string.format("%s ", parser:get_names()) .. "command failed. See 'P4 log'.", vim.log.levels.ERROR)
    end
  end)
end

return M
