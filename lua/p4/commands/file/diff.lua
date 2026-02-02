require("mega.cmdparse")

local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

local M = {}

---@param parent_sub_parser mega.cmdparse.Subparsers
function M.add_parser(parent_sub_parser)

  local parser = parent_sub_parser:add_parser({ name="diff", help = "Diffs the specified file against the head revision." })

  parser:set_execute(function()
    local buf = vim.api.nvim_get_current_buf()

    if vim.api.nvim_buf_is_valid(buf) then
      local file_name = vim.api.nvim_buf_get_name(buf)

      local success, file_list, file_error_list = xpcall(file_api.diff, error_handler_api.process, file_name)

      if success then

        local files = file_list:get_files()
        local file_errors = file_error_list:get_files()

        assert(#files + #file_errors == 1, "Unexpedted number of files")

        if #files > 0 then
          local file = files[1]

          local new_buf = vim.api.nvim_create_buf(false, true)

          vim.bo[new_buf].filetype = vim.bo[buf].filetype
          vim.bo[new_buf].buftype = "nofile"
          vim.bo[new_buf].bufhidden = "hide"
          vim.bo[new_buf].modeline = false
          vim.bo[new_buf].swapfile = false

          vim.api.nvim_buf_set_name(new_buf, file:get_info().path .. "#Head")

          local lines = vim.split(file:get_info().output, "\n")

          if lines[#lines] == "" then
            table.remove(lines, #lines)
          end

          vim.api.nvim_buf_set_lines(new_buf, 0, 1, true, lines)

          vim.bo[new_buf].readonly = true
          vim.bo[new_buf].modifiable = false

          cur_win = vim.api.nvim_get_current_win()

          local win = vim.api.nvim_open_win(new_buf, false, {
            split = "right",
          })

          vim.cmd("wincmd =")
          vim.cmd('windo diffthis')

          vim.api.nvim_set_current_win(cur_win)

          local buf_ac = vim.api.nvim_create_autocmd(
            {
              "WinClosed",
          }, {
            buffer = buf,
            once = true,
            callback = function()
              vim.cmd('diffoff!')

              local clients = vim.lsp.get_clients({bufnr = new_buf})

              for _, client in ipairs(clients) do
                vim.lsp.buf_detach_client(new_buf, client.id)
              end

              vim.api.nvim_buf_delete(new_buf, { force = true })
              vim.api.nvim_win_close(win, true)
            end
          })

          vim.api.nvim_create_autocmd(
            {
              "WinClosed",
          }, {
            buffer = new_buf,
            once = true,
            callback = function()
              vim.cmd('diffoff!')

              local clients = vim.lsp.get_clients({bufnr = new_buf})

              for _, client in ipairs(clients) do
                vim.lsp.buf_detach_client(new_buf, client.id)
              end

              vim.api.nvim_buf_delete(new_buf, { force = true })

              vim.api.nvim_del_autocmd(buf_ac)
            end
          })
        else
          local error_file = file_errors[1]

          notify(string.format("%s: %s", error_file:get_info().path, error_file:get_info().reason), vim.log.levels.WARN)
        end
      end
    end
  end)
end

return M
