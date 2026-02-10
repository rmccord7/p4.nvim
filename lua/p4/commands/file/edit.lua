require("mega.cmdparse")

local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="edit", help = "Open the current buffer for edit." })

  parser:set_execute(function()
    local buf = vim.api.nvim_get_current_buf()

    if vim.api.nvim_buf_is_valid(buf) then
      --TODO: Make releative to WS root
      local file_name = vim.fs.relpath(tostring(vim.uv.cwd()), vim.api.nvim_buf_get_name(buf))

      local success, results, error_results = xpcall(file_api.edit, error_handler_api.process, file_name)

      if success then

        assert(#results + #error_results == 1, "Unexpedted number of files")

        if #results > 0 then
          notify(string.format("%s opened for edit", file_name))

          vim.api.nvim_set_option_value("readonly", false, { buf = buf })
          vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
        else
          local error_result = error_results[1]

          notify(string.format("%s: %s", file_name, error_result.reason), vim.log.levels.WARN)
        end
      end
    end
  end)
end

return M
