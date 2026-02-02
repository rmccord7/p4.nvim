require("mega.cmdparse")

local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="add", help = "Open the current buffer for add." })

  parser:set_execute(function()
    local buf = vim.api.nvim_get_current_buf()

    if vim.api.nvim_buf_is_valid(buf) then
      local file_name = vim.api.nvim_buf_get_name(buf)

      local success, file_list, file_error_list = xpcall(file_api.add, error_handler_api.process, file_name)

      if success then

        local files = file_list:get_files()
        local file_errors = file_error_list:get_files()

        assert(#files + #file_errors == 1, "Unexpedted number of files")

        if #files > 0 then
          local file = files[1]

          notify(string.format("%s opened for add", file:get_info().path))

          vim.api.nvim_set_option_value("readonly", false, { buf = buf })
          vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
        else
          local error_file = file_errors[1]

          notify(string.format("%s: %s", error_file:get_info().path, error_file:get_info().reason), vim.log.levels.WARN)
        end
      end
    end
  end)
end

return M
