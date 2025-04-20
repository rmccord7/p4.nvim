local M = {}

function M.add_parser(parent_subparser)

  local parser = parent_subparser:add_parser({ name="new", help = "Creates a new P4 CL." })

  parser:set_execute(function()
    local cl_api = require("p4.api.cl")

    cl_api.new()
  end)
end

return M
