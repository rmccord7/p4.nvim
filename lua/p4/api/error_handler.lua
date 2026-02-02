local log = require("p4.log")
local notify = require("p4.notify")

local error_api = require("p4.api.error")

--- @class P4_API_Error_Handler
local P4_API_Error_Handler = {}

--- Error handler
---
--- @param err P4_API_Error
function P4_API_Error_Handler.process(err)
  if type(err) == "table" then
    if error_api.is_instance(err) then

      err:log(true)

      notify(string.format("%s. See ':P4 log'.", err:code_to_string()), vim.log.levels.ERROR)
    else
      local trace = debug.traceback(err, 2)

      log.error(trace)

      notify(trace, vim.log.levels.ERROR)
    end
  else
    local trace = debug.traceback(err, 2)

    log.error(trace)

    notify(trace, vim.log.levels.ERROR)
  end
end

return P4_API_Error_Handler
