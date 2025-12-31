local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_History_API
local P4_Telescope_History_API = {}

--- Opens the telescope history picker.
---
--- @param file_path_list string[] One or more files.
--- @param opts? table Optional parameters. Not used.
---
--- @async
function P4_Telescope_History_API.display(file_path_list, opts)

  log.trace("P4_Telescope_History_API: display")

  if require("p4.api.telescope").check() then

    nio.run(function()

      local P4_Revision_List = require("p4.core.lib.revision_list")

      local p4_revision_list = P4_Revision_List:new(file_path_list[1])

      if #p4_revision_list:get() >= 1 then
        vim.schedule(function()
          require("telescope._extensions.p4.pickers.revision").load(vim.fs.basename(file_path_list[1]), p4_revision_list:get())
        end)
      else
        log.fmt_error("No revisions found for the specified file")

        notify("Failed to receive revisions", vim.log.levels.ERROR)
      end
    end)
  end
end

return P4_Telescope_History_API

