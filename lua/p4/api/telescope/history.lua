local telescope_api = require("p4.api.telescope")

--- @class P4_Telescope_History_API
local P4_Telescope_History_API = {}

--- Opens the telescope history picker.
---
--- @param path Local_File_Path Path.
---
--- @async
function P4_Telescope_History_API.display(path)
  vim.validate("path", path, "string")

  if telescope_api.check() then

    local filelog_cmd = require("p4.core.lib.command.filelog")

    local cmd = filelog_cmd:new({path})
    local cmd_results = cmd:run()

    assert(#cmd_results == 1, "Only one file's revision list expected")

    require("telescope._extensions.p4.pickers.revision").load(vim.fs.basename(path), cmd_results[1].data.rev_list)
  end
end

return P4_Telescope_History_API

