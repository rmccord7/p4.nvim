require("mega.cmdparse")

local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="opened", help = "Display the files that are checked out in the current user's P4 client workspace." })

  parser:set_execute(function()

    local success, results, error_results = xpcall(file_api.opened, error_handler_api.process)

    if success then

      if #results > 0 then

        ---@type P4_Telescope_File_Picker_Options
        local new_file_picker = {
          prompt_title = "Opened",
          entry_list = {},
        }

        for _, result in ipairs(results) do

          ---@type P4_Telescope_File_Picker_File_Entry
          local new_entry = {
            path = result.local_path,
            change = result.change,
          }

          table.insert(new_file_picker.entry_list, new_entry)
        end

        local picker = require("telescope._extensions.p4.pickers.file")

        picker.load(new_file_picker)
      end

      if #error_results > 0 then
        local error_result = error_results[1]

        notify(string.format("%s", error_result.reason), vim.log.levels.WARN)
      end
    end
  end)
end

return M
