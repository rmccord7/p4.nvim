local commands = require("p4.commands")

local log = require("p4.core.log")

--- P4 Change List
local M = {}

--- Edits the CL spec
function M.edit_spec(buf, cl)

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
  vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

  vim.api.nvim_buf_set_name(buf, "change list: " .. cl)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()
      local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      result = vim.system(commands.cl.write(cl), { stdin = content }):wait()

      if result.code > 0 then
        log.error(result.stderr)
        return
      end

      vim.api.nvim_buf_delete(buf, { force = true })
    end,
  })
end

--- Get files from CL spec
function M.get_files_from_spec(spec)

  local result
  local files = {}

  for index, line in ipairs(vim.split(spec, "\n")) do

    -- Files in the changelist begin with '#'
    if line:find("#", 1, true) then

      -- CL spec lists files in depot path
      local depot_path = line:sub(1, line:find("#", 1, true) - 1)

      result = log.run_command(commands.file.where(depot_path))

      if result.code == 0 then

        -- Result contains "depot_path client_path file_path"
        local path = {}

        -- Convert to table
        for string in result.stdout:gmatch("%S+") do
          table.insert(path, string)
        end

        -- Third element contains the file path
        table.insert(files, index, path[3])
      end
    end
  end

  return files
end

return M

