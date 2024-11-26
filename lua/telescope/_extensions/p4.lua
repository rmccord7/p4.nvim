local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This extension requires 'telescope.nvim'. (https://github.com/nvim-telescope/telescope.nvim)")
end

local file = require("telescope._extensions.p4.pickers.file")
local cl = require("telescope._extensions.p4.pickers.cl")
local client = require("telescope._extensions.p4.pickers.client")

return telescope.register_extension({
  exports = {
    file = file.file_picker,
    cl = cl.cl_picker,
    client = client.picker,
  },
})
