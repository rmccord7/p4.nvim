local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Client_API
local P4_Telescope_Client_API = {}

--- Gets the current client.
---
--- @return P4_Current_Client? P4 client.
local function get_current_client()

  log.trace("P4_Telescope_Client_API: get_current_client")

  local current_client = require("p4").current_client

  if not current_client then
    notify("Current client not set", vim.log.levels.ERROR)

    log.error("Current client not set")
  end

  return current_client
end

--- Opens the telescope cl picker with the specified client's CLs.
---
--- @param client? string Optional P4 client (Current client is used if nil).
function P4_Telescope_Client_API.display_client_cls(client)

  log.trace("P4_Telescope_Client_API: display_client_cls")

  if require("p4.api.telescope").check then

    --- Gets the CL list for the specified P4 client.
    ---
    --- @param p4_client P4_Client
    local function get_cl_list(p4_client)
      p4_client:update_cl_list(function(success)

        if success then

          vim.schedule(function()

            local p4_cl_list = p4_client:get_cl_list()

            -- No need to query the CL spec here for the CL picker's preview. If we
            -- have it already, then it will be used, but the picker can query it as
            -- well.

            require("telescope._extensions.p4.pickers.cl").load(p4_client.name, p4_cl_list)
          end)
        else
          log.fmt_debug("Failed to update the client's cl list: %s", p4_client.name)
        end
      end)
    end

    nio.run(function()

      if not client then

        local current_client = get_current_client()

        if current_client then

          current_client.semaphore.with(function()
            get_cl_list(current_client)
          end)
        end
      else
        local P4_Client = require("p4.core.lib.client")

        local p4_client = P4_Client:new(client)

        get_cl_list(p4_client)
      end
    end)
  end
end

--- Opens the telescope file picker with the specified client's open files.
---
--- @param client? string Optional P4 client (Current client is used if nil).
function P4_Telescope_Client_API.display_opened_files(client)

  log.trace("P4_Telescope_Client_API: display_opened_files")

  if require("p4.api.telescope").check then

    --- Gets the opened files for the specified P4 client.
    ---
    --- @param p4_client P4_Client
    local function get_opened_files(p4_client)
      p4_client:update_file_list(function(success)

        if success then

          vim.schedule(function()

            -- Run the telescope file picker.
            local picker = require("telescope._extensions.p4.pickers.file")

            picker.load("Opened", p4_client:get_file_list())
          end)
        end
      end)
    end

    nio.run(function()

      if not client then

        local current_client = get_current_client()

        if current_client then

          current_client.semaphore.with(function()
            get_opened_files(current_client)
          end)
        end
      else
        local P4_Client = require("p4.core.lib.client")

        local p4_client = P4_Client:new(client)

        get_opened_files(p4_client)
      end
    end)
  end
end

return P4_Telescope_Client_API
