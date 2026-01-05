local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_Telescope_Client_API
local P4_Telescope_Client_API = {}

--- Opens the telescope cl picker with the specified client's CLs.
---
--- @param client? string Optional P4 client (Current client is used if nil).
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_Telescope_Client_API.display_client_cls(client)
  log.trace("P4_Telescope_Client_API (display_client_cls): Enter")

  local success = require("p4.api.telescope").check()

  if success then

    --- Gets the CL list for the specified P4 client.
    ---
    --- @param p4_client P4_Client
    local function get_cl_list(p4_client)
      success, p4_cl_list = p4_client:get_pending_cl_list()

      if success then

        vim.schedule(function()
          -- No need to query the CL spec here for the CL picker's preview. If we have it already, then it will be used,
          -- but the picker can query it as well.

          require("telescope._extensions.p4.pickers.cl").load(p4_client:get_name(), p4_cl_list)
        end)
      else
        log.fmt_debug("Failed to update the client's cl list: %s", p4_client:get_name())
      end
    end

    if not client then

      local P4_Context = require("p4.context")

      local current_client = P4_Context.get_current_client()

      if current_client then
        get_cl_list(current_client)
      end
    else
      local P4_Client = require("p4.core.lib.client")

      success, p4_client = P4_Client:new(client)

      if success and p4_client then
        get_cl_list(p4_client)
      end
    end
  end

  log.trace("P4_Telescope_Client_API (display_client_cls): Exit")

  return success
end

--- Opens the telescope file picker with the specified client's open files.
---
--- @param client? string Optional P4 client (Current client is used if nil).
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_Telescope_Client_API.display_opened_files(client)
  log.trace("P4_Telescope_Client_API (display_opened_files): Enter")

  local success = require("p4.api.telescope").check()

  if success then

    --- Gets the opened files for the specified P4 client.
    ---
    --- @param p4_client P4_Client
    local function get_opened_files(p4_client)
      success, p4_file_list = p4_client:get_open_files()

      if success and p4_file_list then

        if #p4_file_list:get_file_paths() > 1 then

          -- Run the telescope file picker.
          local picker = require("telescope._extensions.p4.pickers.file")

          picker.load("Opened", p4_file_list)
        else
          notify("No files are open in the client workspace.")
        end
      end
    end

    if not client then

      local P4_Context = require("p4.context")

      local current_client = P4_Context.get_current_client()

      if current_client then
        get_opened_files(current_client)
      end
    else
      local P4_Client = require("p4.core.lib.client")

      success, p4_client = P4_Client:new(client)

      if success then
        get_opened_files(p4_client)
      end
    end
  end

  log.trace("P4_Telescope_Client_API (display_opened_files): Exit")

  return success
end

return P4_Telescope_Client_API
