local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires 'telescope.nvim'. (https://github.com/nvim-telescope/telescope.nvim)")
end

local client = require("telescope._extensions.p4.pickers.client")
local clients = require("telescope._extensions.p4.pickers.clients")

return telescope.register_extension({
  exports = {
    clients = clients.picker,
    change_lists = client.pending_cl_picker,
  },
})
