local util = require("p4.util")

local M = {}

function M.command(cmd)

  if type(cmd) == 'table' then
    util.debug(string.format("Command: '%s'", table.concat(cmd, ' ')))
  else
    util.debug(string.format("Command: '%s'", cmd))
  end
end

return M
