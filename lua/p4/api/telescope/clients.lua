local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Clients_API
local P4_Telescope_Clients_API = {}

--- Opens the telescope clients picker.
---
--- @async
function P4_Telescope_Clients_API.display()

  log.trace("P4_Telescope_Clients_API: display")

  if require("p4.api.telescope").check() then

    nio.run(function()

      local P4_Command_Clients = require("p4.core.lib.command.clients")

      local success, result_list = P4_Command_Clients:new():run()

      if success then
        log.trace("Successfully received clients.")

        --- @cast result_list P4_Command_Clients_Result[]

        local client_list = {}

        for _, result in ipairs(result_list) do
          table.insert(client_list, result.client_name)
        end

        local P4_Client_List = require("p4.core.lib.client_list")

        local p4_client_list
        success, p4_client_list = P4_Client_List:new(client_list)

        if success and p4_client_list then
          vim.schedule(function()
            require("telescope._extensions.p4.pickers.client").load("Clients", p4_client_list:get_clients())
          end)
        end
      else
        log.fmt_error("Failed to receive the clients")

        notify("API Failed", vim.log.levels.ERROR)
      end
    end)
  end
end

return P4_Telescope_Clients_API
