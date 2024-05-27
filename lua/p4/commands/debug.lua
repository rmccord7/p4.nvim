local debug = require("p4.debug")

local M = {}

function M.command(cmd)

  if type(cmd) == 'table' then
    debug.print(string.format("Command: '%s'", table.concat(cmd, ' ')))
  else
    debug.print(string.format("Command: '%s'", cmd))
  end
end

return M
