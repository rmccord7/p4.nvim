local log = require("p4.log")
local notify = require("p4.notify")

local file_api = require("p4.api.file")
local error_handler_api = require("p4.api.error_handler")

--- @class P4_Telescope_Client_API
local P4_Telescope_Client_API = {}

--- Opens the telescope file picker with the specified client's open files.
---
--- @param client? string Optional P4 client (Current client is used if nil).
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_Telescope_Client_API.display_opened_files(client)
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

  return success
end

return P4_Telescope_Client_API
