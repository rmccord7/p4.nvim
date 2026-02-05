require("mega.cmdparse")

local notify = require("p4.notify")

local telescope_file_api = require("p4.api.telescope.history")
local error_handler_api = require("p4.api.error_handler")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="history", help = "Displays the P4 file history for the specified file." })

  parser:set_execute(function()
    local buf = vim.api.nvim_get_current_buf()

    if vim.api.nvim_buf_is_valid(buf) then
      local file_name = vim.api.nvim_buf_get_name(buf)

      local success = xpcall(telescope_file_api.display, error_handler_api.process, file_name)

      if not success then
        notify(string.format("%s: %s", file_name, error_file:get_info().reason), vim.log.levels.WARN)
      end
    end
  end)
end

return M
