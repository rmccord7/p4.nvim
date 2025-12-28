local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Context
--- @field protected current_client P4_Current_Client? Current client
local P4_Context = {}

-- Check if telescope is supported
 local has_telescope, _ = pcall(require, "telescope")

 if has_telescope then

   P4_Context.telescope = true
 else
   P4_Context.telescope = false
 end

--- Gets the current client.
---
--- @async
function P4_Context.update_current_client()
  log.trace("P4_Context (update_current_client): Enter")

  local p4_context = require("p4.context")
  local p4_env = require("p4.core.env")
  local P4_Current_Client = require("p4.core.lib.current_client")

  -- Only update the current client if it has not already been done or the current client does not match what was
  -- previously set.
  if not p4_context.current_client or p4_context.current_client:get_name() ~= p4_env.client then

    -- Create new current client.
    local success, new_current_client = P4_Current_Client:new(p4_env.client)

    if success and new_current_client then

      -- Read current client's spec from P4 server.
      success = new_current_client:get_spec()

      if success then
        p4_context.current_client = new_current_client
      end
    end
  end

  log.trace("P4_Context (update_current_client): Exit")
end

--- Gets the current client.
---
--- @return P4_Current_Client? P4 client.
---
--- @nodiscard
--- @async
function P4_Context.get_current_client()

  log.trace("P4_Telescope_Client_API: get_current_client")

  P4_Context.update_current_client()

  if not P4_Context.current_client then

    notify("Current client not set", vim.log.levels.ERROR)

    log.error("Current client not set")
  end

  return P4_Context.current_client
end

return P4_Context
