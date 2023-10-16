local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires 'telescope.nvim'. (https://github.com/nvim-telescope/telescope.nvim)")
end

local config = require("telescope._extensions.p4.config")
local p_clients = require("telescope._extensions.p4.pickers.clients")
local p_client = require("telescope._extensions.p4.pickers.client")

return telescope.register_extension({
  setup = config.setup,
  exports = {
    clients = p_clients.picker,
    change_lists = p_client.pending_cl_picker,
  },
})
