local log = require("p4.log")

--- @class P4_Telescope_Clients_API
local P4_Telescope_Clients_API = {}

--- Opens the telescope clients picker.
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_Telescope_Clients_API.display()
  log.trace("P4_Telescope_Clients_API (display): Enter")

  local success = require("p4.api.telescope").check()

  if success then

    local P4_Command_Clients = require("p4.core.lib.command.clients")

    local results
    success, results = P4_Command_Clients:new():run()

    if success and results then
      log.trace("Successfully received clients.")

      local client_list = {}

      for _, result in ipairs(results) do
        if result.success then
          table.insert(client_list, result.data.Client)
        else
          -- There will only be one error result if we were unable to get the clients.
          success = false
          break
        end
      end

      if success then
        local P4_Client_List = require("p4.core.lib.client_list")

        local p4_client_list
        success, p4_client_list = P4_Client_List:new(client_list)

        if success and p4_client_list then
          vim.schedule(function()
            require("telescope._extensions.p4.pickers.client").load("Clients", p4_client_list:get_clients())
          end)
        end
      end
    else
      log.fmt_error("Failed to receive the clients")
    end
  end

  log.trace("P4_Telescope_Clients_API (display): Exit")

  return success
end

return P4_Telescope_Clients_API
