local error_api = require("p4.api.error")

local file_list_lib = require("p4.core.lib.file_list")
local file_lib = require("p4.core.lib.file")

--- @class P4_File_API
local P4_File_API = {}

--- @class P4_File_API_Add_Result_Success
--- @field depot_path Depot_File_Path
--- @field local_path Local_File_Path
--- @field action P4_Action Always "add"
--- @field revision string Working revision number.

--- @class P4_File_API_Add_Result_Error
--- @field depot_path Depot_File_Path
--- @field reason string Reason could not be opened for add.

--- Opens one or more files for add.
---
--- This function should be called with xpcall() with the p4 api error handler to catch/log/notify any errors that have
--- occured.
---
--- The P4 add command will open a file for add even if it does not yet exist on the file system.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
---
--- @return P4_File_API_Add_Result_Success[] results List of P4 files that were successfully opened for add.
--- @return P4_File_API_Add_Result_Error[] error_results List of P4 files that could not be opened for add.
---
--- @async
--- @nodiscard
function P4_File_API.add(file_specs)
  vim.validate("file_specs", file_specs, {"string", "table"})

  if type(file_specs) == "string" then
    file_specs = {file_specs}
  elseif type(file_specs) == "table" then
    for _, v in ipairs(file_specs) do
      vim.validate(v, "v", "string")
    end
  end

  local results = {} ---@type P4_File_API_Add_Result_Success[]
  local error_results = {} ---@type P4_File_API_Add_Result_Error[]

  local add_cmd = require("p4.core.lib.command.add")

  local cmd = add_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local success_data = cmd_result.data

      ---@cast success_data P4_Command_Add_Result_Success

      --- @type P4_File_API_Add_Result_Success
      local new_result = {
        depot_path = success_data.depotFile,
        local_path = success_data.clientFile, -- clientFile returned in local syntax for some reason.
        action = success_data.action,
        revision = success_data.workRev,
      }

      table.insert(results, new_result)
    else

      local error_data = cmd_result.data

      ---@cast error_data P4_Command_Add_Result_Error

      --- @type P4_File_API_Add_Result_Error
      local new_error_result = {
        depot_path = error_data.depotFile,
        reason = error_data.reason,
      }

      table.insert(error_results, new_error_result)
    end
  end

  return results, error_results
end

--- @class P4_File_API_Edit_Result_Success
--- @field depot_path Depot_File_Path
--- @field local_path Local_File_Path
--- @field action P4_Action Always "edit"
--- @field revision string Working revision number.

--- @class P4_File_API_Edit_Result_Error
--- @field depot_path Depot_File_Path
--- @field reason string Reason could not be opened for edit.

--- Opens one or more files for edit.
---
--- This function should be called with xpcall() with the p4 api error handler to catch/log/notify any errors that have
--- occured.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
---
--- @return P4_File_API_Edit_Result_Success[] results List of P4 files that were successfully opened for edit.
--- @return P4_File_API_Edit_Result_Error[] error_results List of P4 files that could not be opened for edit.
---
--- @async
--- @nodiscard
function P4_File_API.edit(file_specs)
  vim.validate("file_specs", file_specs, {"string", "table"})

  if type(file_specs) == "string" then
    file_specs = {file_specs}
  elseif type(file_specs) == "table" then
    for _, v in ipairs(file_specs) do
      vim.validate(v, "v", "string")
    end
  end

  local results = {} ---@type P4_File_API_Edit_Result_Success[]
  local error_results = {} ---@type P4_File_API_Edit_Result_Error[]

  local edit_cmd = require("p4.core.lib.command.edit")

  local cmd = edit_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local success_data = cmd_result.data

      ---@cast success_data P4_Command_Edit_Result_Success

      --- @type P4_File_API_Edit_Result_Success
      local new_result = {
        depot_path = success_data.depotFile,
        local_path = success_data.clientFile, -- clientFile returned in local syntax for some reason.
        action = success_data.action,
        revision = success_data.workRev,
      }

      table.insert(results, new_result)
    else

      local error_data = cmd_result.data

      ---@cast error_data P4_Command_Edit_Result_Error

      --- @type P4_File_API_Edit_Result_Error
      local new_error_result = {
        depot_path = error_data.depotFile,
        reason = error_data.reason,
      }

      table.insert(error_results, new_error_result)
    end
  end

  return results, error_results
end

--- @class P4_File_API_Revert_Result_Success
--- @field depot_path Depot_File_Path
--- @field local_path Local_File_Path
--- @field action P4_Action Always "abandoned" or "reverted".
--- @field revision string Have revision number.

--- @class P4_File_API_Revert_Result_Error
--- @field depot_path Depot_File_Path
--- @field reason string Reason could not be opened for edit.

--- Reverts one or more files.
---
--- This function should be called with xpcall() with the p4 api error handler to catch/log/notify any errors that have
--- occured.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
---
--- @return P4_File_API_Revert_Result_Success[] results List of P4 files that were successfully reverted.
--- @return P4_File_API_Revert_Result_Error[] error_results List of P4 files that could not be reverted.
---
--- @async
--- @nodiscard
function P4_File_API.revert(file_specs)
  vim.validate("file_specs", file_specs, {"string", "table"})

  if type(file_specs) == "string" then
    file_specs = {file_specs}
  elseif type(file_specs) == "table" then
    for _, v in ipairs(file_specs) do
      vim.validate(v, "v", "string")
    end
  end

  local results = {} ---@type P4_File_API_Revert_Result_Success[]
  local error_results = {} ---@type P4_File_API_Revert_Result_Error[]

  local revert_cmd = require("p4.core.lib.command.revert")

  local cmd = revert_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local success_data = cmd_result.data

      ---@cast success_data P4_Command_Revert_Result_Success

      --- @type P4_File_API_Revert_Result_Success
      local new_result = {
        depot_path = success_data.depotFile,
        local_path = success_data.clientFile, -- clientFile returned in local syntax for some reason.
        action = success_data.action,
        revision = success_data.haveRev,
      }

      table.insert(results, new_result)
    else

      local error_data = cmd_result.data

      ---@cast error_data P4_Command_Revert_Result_Error

      --- @type P4_File_API_Revert_Result_Error
      local new_error_result = {
        depot_path = error_data.depotFile,
        reason = error_data.reason,
      }

      table.insert(error_results, new_error_result)
    end
  end

  return results, error_results
end

--- Shelves the specified files in the current client workspace.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
--- @return P4_File_API_Revert_Result_Success[] results List of P4 files that were successfully reverted.
--- @return P4_File_API_Revert_Result_Error[] error_results List of P4 files that could not be reverted.
---
--- @async
--- @nodiscard
function P4_File_API.shelve(file)
  --TODO:
end

--- @class P4_File_API_Print_Result_Success
--- @field depot_path Depot_File_Path
--- @field action P4_Action Current file state for the specified revision.
--- @field change string Current file changelist for the specified revision.
--- @field file_size string Current file size for the specified revision.
--- @field revision string Current revision.
--- @field time string Time of the last revision.
--- @field output string File output for the specified revision.

--- @class P4_File_API_Print_Result_Error
--- @field depot_path Depot_File_Path
--- @field reason string Reason could not be opened for edit.

--- Gets the output for one or more file revisions.
---
--- This function should be called with xpcall() with the p4 api error handler to catch/log/notify any errors that have
--- occured.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
---
--- @return P4_File_API_Print_Result_Success[] results List of P4 files that were successfully diffed.
--- @return P4_File_API_Print_Result_Error[] error_results List of P4 files that could not be diffed.
---
--- @async
--- @nodiscard
function P4_File_API.print(file_specs)
  vim.validate("file_specs", file_specs, {"string", "table"})

  --TODO: Check for revision marker?

  if type(file_specs) == "string" then
    file_specs = {file_specs}
  elseif type(file_specs) == "table" then
    for _, v in ipairs(file_specs) do
      vim.validate(v, "v", "string")
    end
  end

  local print_cmd = require("p4.core.lib.command.print")

  local results = {} ---@type P4_File_API_Print_Result_Success[]
  local error_results = {} ---@type P4_File_API_Print_Result_Error[]

  local cmd = print_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local success_data = cmd_result.data

      ---@cast success_data P4_Command_Print_Result_Success

      --- @type P4_File_API_Print_Result_Success
      local new_result = {
        depot_path = success_data.depotFile,
        action = success_data.action,
        change = success_data.change,
        file_size = success_data.fileSize,
        revision = success_data.rev,
        time = success_data.time,
        output = success_data.output
      }

      table.insert(results, new_result)
    else

      local error_data = cmd_result.data

      ---@cast error_data P4_Command_Print_Result_Error

      --- @type P4_File_API_Print_Result_Error
      local new_error_result = {
        depot_path = error_data.depotFile,
        reason = error_data.reason,
      }

      table.insert(error_results, new_error_result)
    end
  end

  return results, error_results
end

--- @class P4_File_API_Opened_Result_Success
--- @field depot_path Depot_File_Path
--- @field local_path Local_File_Path
--- @field action P4_Action
--- @field have_revision string Current workspace revision.
--- @field revision string
--- @field user string
--- @field change string

--- @class P4_File_API_Opened_Result_Error
--- @field reason string Reason could not be opened for edit.

--- Returns a list of files that are open in the client workspace.
---
--- This function should be called with xpcall() with the p4 api error handler to catch/log/notify any errors that have
--- occured.
---
--- @param file_specs (File_Spec | File_Spec[])? One or more file specs.
--- @param change string? Restrict results to files open in the specified CL.
---
--- @return P4_File_API_Opened_Result_Success[] results List of P4 files that were successfully reverted.
--- @return P4_File_API_Opened_Result_Error[] error_results List of P4 files that could not be reverted.
---
--- @async
--- @nodiscard
function P4_File_API.opened(file_specs, change)
  vim.validate("file_specs", file_specs, {"string", "table"}, true)
  vim.validate("change", change, "string", true)

  if file_specs then
    if type(file_specs) == "string" then
      file_specs = {file_specs}
    elseif type(file_specs) == "table" then
      for _, v in ipairs(file_specs) do
        vim.validate(v, "v", "string")
      end
    end
  end

  local results = {} ---@type P4_File_API_Opened_Result_Success[]
  local error_results = {} ---@type P4_File_API_Opened_Result_Error[]

  local opened_cmd = require("p4.core.lib.command.opened")

  local cmd = opened_cmd:new()
  local cmd_results = cmd:run()

  if cmd_results then
    for _, cmd_result in ipairs(cmd_results) do

      if cmd_result.success then

        local success_data = cmd_result.data

        ---@cast success_data P4_Command_Opened_Result_Success

        --- @type P4_File_API_Opened_Result_Success
        local new_result = {
          depot_path = success_data.depotFile,
          local_path = success_data.clientFile:gsub("//" .. success_data.client .. "/", "", 1), -- We have the client so we can just convert.
          action = success_data.action,
          have_revision = success_data.haveRev,
          revision = success_data.rev,
          user = success_data.user,
          change = success_data.change,
        }

        table.insert(results, new_result)
      else

        local error_data = cmd_result.data

        ---@cast error_data P4_Command_Opened_Result_Error

        --- @type P4_File_API_Opened_Result_Error
        local new_error_result = {
          reason = error_data.reason,
        }

        table.insert(error_results, new_error_result)
      end
    end
  end

  return results, error_results
end


return P4_File_API
