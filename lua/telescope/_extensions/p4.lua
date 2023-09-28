local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires 'telescope.nvim'. (https://github.com/nvim-telescope/telescope.nvim)")
end

local telescope_p4_config = require("telescope._extensions.p4.config")
local telescope_p4_picker = require("telescope._extensions.p4.picker")

return telescope.register_extension({
  setup = telescope_p4_config.setup,
  exports = {
    clients = telescope_p4_picker.clients_picker,
    change_lists = telescope_p4_picker.change_lists_picker,
  },
})
