local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Client_API
local P4_Telescope_Client_API = {}

--- Gets the current client.
---
--- @return nio.control.Future future Future to wait on.
--- @nodiscard
--- @async
local function update_current_client()

  log.trace("P4_Telescope_Client_API: update_current_client")

  local future = nio.control.future()

  local p4 = require("p4")
  local p4_env = require("p4.core.env")
  local P4_Current_Client = require("p4.core.lib.current_client")

  -- Only update the current client if it has not already been done or the current client does not match what was
  -- previously set.
  if not p4.current_client or p4.current_client.name ~= p4_env.client then

    -- Create new current client.
    local new_current_client = P4_Current_Client:new(p4_env.client)

    -- Read current client's spec from P4 server.
    local success = pcall(new_current_client:read_spec().wait)

    if success then
      p4.current_client = new_current_client

      future.set(p4.current_client)
    else
      future.set_error()
    end
  end

  return future
end

--- Gets the current client.
---
--- @return P4_Current_Client? P4 client.
--- @nodiscard
--- @async
local function get_current_client()

  log.trace("P4_Telescope_Client_API: get_current_client")

  local p4_env = require("p4.core.env")

  local env_valid = p4_env.check(true)

  if env_valid then

    local success, current_client = pcall(update_current_client().wait)

    if not success then
      notify("Current client not set", vim.log.levels.ERROR)

      log.error("Current client not set")
    end

    return current_client
  end

  return nil
end

--- Opens the telescope cl picker with the specified client's CLs.
---
--- @param client? string Optional P4 client (Current client is used if nil).
--- @async
function P4_Telescope_Client_API.display_client_cls(client)

  log.trace("P4_Telescope_Client_API: display_client_cls")

  if require("p4.api.telescope").check() then

    --- Gets the CL list for the specified P4 client.
    ---
    --- @param p4_client P4_Client
    local function get_cl_list(p4_client)
      local success = pcall(p4_client:update_cl_list().wait)

      if success then

        vim.schedule(function()

          local p4_cl_list = p4_client:get_cl_list()

          if p4_cl_list then

            -- No need to query the CL spec here for the CL picker's preview. If we
            -- have it already, then it will be used, but the picker can query it as
            -- well.

            require("telescope._extensions.p4.pickers.cl").load(p4_client.name, p4_cl_list)
          else
            notify("No CLs are pending in the client workspace.")
          end
        end)
      else
        log.fmt_debug("Failed to update the client's cl list: %s", p4_client.name)
      end
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
--- @async
function P4_Telescope_Client_API.display_opened_files(client)

  log.trace("P4_Telescope_Client_API: display_opened_files")

  if require("p4.api.telescope").check() then

    --- Gets the opened files for the specified P4 client.
    ---
    --- @param p4_client P4_Client
    local function get_opened_files(p4_client)
      local success = pcall(p4_client:update_file_list().wait)

      if success then

        vim.schedule(function()

          local p4_file_list = p4_client:get_file_list()

          if p4_file_list then

            -- Run the telescope file picker.
            local picker = require("telescope._extensions.p4.pickers.file")

            picker.load("Opened", p4_file_list)
          else
            notify("No files are open in the client workspace.")
          end
        end)
      end
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
