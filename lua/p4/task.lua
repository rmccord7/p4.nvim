local log = require("p4.log")
local notify = require("p4.notify")

--- @class Task : table
local Task = {}

--- Handles errors if a task has failed.
---
--- @param on_exit? fun(success: boolean, ...) Callback function when function completes
--- @param success boolean Indicates if the function was successful.
function Task.complete(on_exit, success, ...)
  if not success then
    local error, trace = ...

    notify("Task failed. See ':P4 log' for more info.", vim.log.levels.ERROR)

    log.error(error, trace)

    if on_exit then
      on_exit(success, ...)
    end
  end
end

return Task
