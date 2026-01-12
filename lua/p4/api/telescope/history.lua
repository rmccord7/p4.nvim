local log = require("p4.log")

--- @class P4_Telescope_History_API
local P4_Telescope_History_API = {}

--- Opens the telescope history picker.
---
--- @param file string File.
--- @return boolean success Result of the function.
---
--- @nodiscard
--- @async
function P4_Telescope_History_API.display(file)
  log.trace("P4_Telescope_History_API (display): Enter")

  local success = false

  if require("p4.api.telescope").check() then

    -- Issue P4 filelog command to request the specified file's history.
    local P4_Command_FileLog = require("p4.core.lib.command.filelog")

    local results
    success, results = P4_Command_FileLog:new({file}):run()

    if success and results then

      assert(#results == 1, "Unexpected number of results")

      --- @cast results P4_Command_Filelog_Result[]

      if #results then
        require("telescope._extensions.p4.pickers.revision").load(vim.fs.basename(file), results[1].data.rev_list)
      else
        log.fmt_error("No revisions found for the specified file")

        success = false
      end
    end
  end

  log.trace("P4_Telescope_History_API (display): Exit")

  return success
end

return P4_Telescope_History_API

