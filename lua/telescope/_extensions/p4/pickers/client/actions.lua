local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Client_Actions
local P4_Telescope_Client_Actions = {}

--- Action to edit a P4 client spec.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
 function P4_Telescope_Client_Actions.edit_client_spec(prompt_bufnr)

  log.trace("Telescope_Client_Actions: edit_client_spec")

  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then

    -- local bufnr = require("telescope.state").get_global_key("last_preview_bufnr")

    local P4_Client_API = require("p4.api.client")

    --FIX: Use preview buffer
    P4_Client_API.new(entry.name)
  end
end

--- Action to delete the P4 client.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_Client_Actions.delete_client(prompt_bufnr)

  log.trace("Telescope_Client_Actions: delete_client")

  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement deleting the client

    notify("Not supported", vim.log.level.ERROR);
  else
  end
end

--- Action to select P4 client.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function P4_Telescope_Client_Actions.select_client(prompt_bufnr)

  log.trace("Telescope_Client_Actions: select_client")

  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement changing workspaces

    notify("Not supported", vim.log.level.ERROR);
  else
  end
end

return P4_Telescope_Client_Actions
