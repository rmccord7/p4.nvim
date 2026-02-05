local log = require("p4.log")

local error_api = require("p4.api.error")

local file_list_lib = require("p4.core.lib.file_list")
local file_lib = require("p4.core.lib.file")
local file_error_list_lib = require("p4.core.lib.file_error_list")
local file_error_lib = require("p4.core.lib.file_error")

--- @class P4_File_API
local P4_File_API = {}

--- Opens one or more files for add.
---
--- Files that are not mapped to the client worksapce or do not exist in the depot will be excluded from the list of
--- depot paths that are returned from this function.
---
--- A file that is already open for edit will be included in the list of depot paths that are returned by this function.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
--- @return P4_File_List result List of P4 files that are opened for add.
--- @return P4_File_Error_List error_result List of P4 files that could not be opened for add.
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

  local add_cmd = require("p4.core.lib.command.add")

  local new_file_list = file_list_lib:new()
  local new_error_file_list = file_error_list_lib:new()

  local cmd = add_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Add_Result_Success

      --- @type P4_File_Info
      local new_file_params = {
        path = {
          host = file_info.clientFile, -- clientFile returned in local syntax for some reason.
          depot = file_info.depotFile,
        },
        action = file_info.action,
        work_rev = file_info.workRev,
      }

      local new_file = file_lib:new(new_file_params)

      new_file_list:add_file(new_file)
    else

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Add_Result_Error

      --- @type P4_File_Error_Info
      local new_file_error_params = {
        path = file_info.depotFile,
        reason = file_info.reason,
      }

      local new_file_error = file_error_lib:new(new_file_error_params)

      new_error_file_list:add_file(new_file_error)
    end
  end

  return new_file_list, new_error_file_list
end

--- Opens one or more files for edit.
---
--- Files that are not mapped to the client worksapce or do not exist in the depot will be excluded from the list of
--- depot paths that are returned from this function.
---
--- A file that is already open for edit will be included in the list of depot paths that are returned by this function.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
--- @return P4_File_List result List of P4 files that are opened for edit.
--- @return P4_File_Error_List error_result List of P4 files that could not be opened for add.
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

  local edit_cmd = require("p4.core.lib.command.edit")

  local new_file_list = file_list_lib:new()
  local new_error_file_list = file_error_list_lib:new()

  local cmd = edit_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Edit_Result_Success

      --- @type P4_File_Info
      local new_file_params = {
        path = {
          host = file_info.clientFile, -- clientFile returned in local syntax for some reason.
          depot = file_info.depotFile,
        },
        action = file_info.action,
        work_rev = file_info.workRev,
      }

      local new_file = file_lib:new(new_file_params)

      new_file_list:add_file(new_file)
    else

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Edit_Result_Error

      --- @type P4_File_Error_Info
      local new_file_error_params = {
        path = file_info.depotFile,
        reason = file_info.reason,
      }

      local new_file_error = file_error_lib:new(new_file_error_params)

      new_error_file_list:add_file(new_file_error)
    end
  end

  return new_file_list, new_error_file_list
end

--- Reverts one or more files.
---
--- @param file_specs File_Spec | File_Spec[] One or more file specs.
--- @return P4_File_List result List of P4 files that were reverted.
--- @return P4_File_Error_List error_result List of P4 files that could not be reverted.
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

  local new_file_list = file_list_lib:new()
  local new_error_file_list = file_error_list_lib:new()

  local revert_cmd = require("p4.core.lib.command.revert")

  local cmd = revert_cmd:new(file_specs)
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Revert_Result_Success

      --- @type P4_File_Info
      local new_file_params = {
        path = {
          host = file_info.clientFile, -- clientFile returned in local syntax for some reason.
          depot = file_info.depotFile,
        },
        action = file_info.action,
        have_rev = file_info.haveRev,
        -- old_action = file_info.oldAction -- Not currently used
      }

      local new_file = file_lib:new(new_file_params)

      new_file_list:add_file(new_file)
    else

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Revert_Result_Error

      --- @type P4_File_Error_Info
      local new_file_error_params = {
        path = file_info.depotFile,
        reason = file_info.reason,
      }

      local new_file_error = file_error_lib:new(new_file_error_params)

      new_error_file_list:add_file(new_file_error)
    end
  end

  return new_file_list, new_error_file_list
end

--- Shelves the specified files in the current client workspace.
---
--- @param file string File.
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_File_API.shelve(file)
  log.trace("P4_File_API (shelve): Enter")

  local success = false

  if type(file) == "string" then
    local p4_file
    sucess, p4_file = create_p4_file(file)

    if success and p4_file then

      local P4_Command_Shelve = require("p4.core.lib.command.shelve")

      success = P4_Command_Shelve:new({file}):run()

      if success then

        log.fmt_debug("File shelved: %s", file)
      end
    end
  else
    log.fmt_error("P4_File_API (shelve): Invalid parameter")
  end

  log.trace("P4_File_API (shelve): Exit")

  return success
end

--TODO: Diff something other than head.

--- Enters diffmode with the specified file diff-ed against the head revision.
---
--- @param path Local_File_Path File path.
---
--- @return P4_File_List result List of P4 files that were reverted.
--- @return P4_File_Error_List error_result List of P4 files that could not be reverted.
---
--- @async
--- @nodiscard
function P4_File_API.diff(path)
  vim.validate("path", path, "string")

  local print_cmd = require("p4.core.lib.command.print")

  local new_file_list = file_list_lib:new()
  local new_error_file_list = file_error_list_lib:new()

  local cmd = print_cmd:new({path})
  local cmd_results = cmd:run()

  for _, cmd_result in ipairs(cmd_results) do

    if cmd_result.success then

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Print_Result_Success

      --- @type P4_File_Info
      local new_file_params = {
        path = {
          depot = file_info.depotFile,
        },
        action = file_info.action,
        change = file_info.change,
        file_size = file_info.fileSize,
        rev = file_info.rev,
        time = file_info.time,
        output = file_info.output
      }

      local new_file = file_lib:new(new_file_params)

      new_file_list:add_file(new_file)
    else

      local file_info = cmd_result.data

      ---@cast file_info P4_Command_Print_Result_Error

      --- @type P4_File_Error_Info
      local new_file_error_params = {
        path = file_info.depotFile,
        reason = file_info.reason,
      }

      local new_file_error = file_error_lib:new(new_file_error_params)

      new_error_file_list:add_file(new_file_error)
    end
  end

  return new_file_list, new_error_file_list
end

--- Returns a list of open files.
---
--- @param file_specs (File_Spec | File_Spec[])? One or more file specs.
--- @param change string? Restrict results to files open in the specified CL.
--- @return P4_File_List result Returns a list of open files. If no files are open, then the file list will be empty.
---
--- @async
--- @nodiscard
function P4_File_API.get_open_files(file_specs, change)
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
  local opened_cmd = require("p4.core.lib.command.opened")

  local new_file_list = file_list_lib:new()

  local cmd = opened_cmd:new()
  local cmd_results = cmd:run()

  if cmd_results then
    for _, cmd_result in ipairs(cmd_results) do

      if cmd_result.success then

        local file_info = cmd_result.data

        ---@cast file_info P4_Command_Opened_Result_Success

        --- @type P4_File_Info
        local new_file_params = {
          path = {
            host = file_info.clientFile:gsub("//" .. file_info.client .. "/", "", 1), -- We have the client so we can just convert.
            client = file_info.clientFile,
            depot = file_info.depotFile,
          },
          action = file_info.action,
          have_rev = file_info.haveRev,
          rev = file_info.rev,
          user = file_info.user,
          change = file_info.change,
        }

        local new_file = file_lib:new(new_file_params)

        new_file_list:add_file(new_file)
      else

        -- This command doesn't support error results.
        error(error_api:new(P4_RESULT_CODE_UNLIKELY))
      end
    end
  end

  return new_file_list
end


return P4_File_API
