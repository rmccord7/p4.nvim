local config = require("p4.config")

local p4 = {}

function.setup(options)

  if vim.fn.has("nvim-0.7.2") == 0 then
    util.error("P4 needs Neovim >= 0.7.2")
    return
  end

  config.setup(options)

end

return p4
