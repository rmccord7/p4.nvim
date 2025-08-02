local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="log", help = "View P4 output." })

  parser:set_execute(function()
    local p4_log = require("p4.core.log")

    vim.cmd(([[tabnew %s]]):format(p4_log.outfile))
  end)
end

return M
