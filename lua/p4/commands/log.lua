local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="log", help = "View the plugin log." })

  parser:set_execute(function()
    local log = require("p4.log")

    vim.cmd(([[tabnew %s]]):format(log.outfile))
  end)
end

return M
