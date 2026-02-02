require("mega.cmdparse")

local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="opened", help = "Display the files that are checked out in the current user's P4 client workspace." })

  parser:set_execute(function()

    local success, file_list = xpcall(file_api.get_open_files, error_handler_api.process)

    if success then

      if #file_list:get_files() > 0 then
        local picker = require("telescope._extensions.p4.pickers.file")

        picker.load("Opened", file_list)
      else
        notify("No files opened ", vim.log.levels.WARN)
      end
    end
  end)
end

return M
