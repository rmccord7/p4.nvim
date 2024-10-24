local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local p4_notify = require("p4.notify")

local p4_client = require("p4.api.client")

local tp4_util = require("telescope._extensions.p4.pickers.util")

local M = {}

--- Action to edit a P4 client spec.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
 function M.edit_client_spec(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then

    local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

    -- Entry name is the client name
    local client = p4_client.new(entry.name)

    if bufnr then
      client:edit_spec(bufnr)
    end

  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to delete the P4 client.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.delete_client(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement deleting the client

    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to select P4 client.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.select_client(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement changing workspaces

    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

return M
