local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_File_API
local P4_File_API = {}

--- Creates a P4 file from the specified file.
---
--- @param file string File.
--- @return boolean success True if this function is successful.
--- @return P4_File? result Function result.
---
--- @async
--- @nodiscard
local function create_p4_file(file)

  local P4_File = require("p4.core.lib.file")

  ---@type P4_File_New
  local new_p4_file = {
    path = file,
    check_in_depot = true,
    get_stats = true,
  }

  return P4_File:new(new_p4_file)
end

--- Creates a P4 file list from the specified files.
---
--- @param files string[] One or more files.
--- @return boolean success True if this function is successful.
--- @return P4_File_List? result Function result.
---
--- @async
--- @nodiscard
local function create_p4_file_list(files)

  local P4_File_List = require("p4.core.lib.file_list")

  ---@type P4_File_List_New
  local new_file_list = {
    paths = files,
    convert_depot_paths = false,
    check_in_depot = true,
    get_stats = true,
  }

  return(P4_File_List:new(new_file_list))
end

--- Adds the specified file to the current client workspace.
---
--- @param file string File.
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_API.add(file)
  log.trace("P4_File_API (add): Enter")

  local success = false

  if type(file) == "string" then

    success, p4_file = create_p4_file(file)

    if success and p4_file then

      success = p4_file:add()

      if success then
        notify("File opened for add: " .. file)

        log.fmt_debug("File opened for add: %s", file)
      end
    end
  else
    log.fmt_error("P4_File_API (add): Invalid parameter")
  end

  log.trace("P4_File_API (add): Exit")

  return success
end

--- Adds the specified files to the current client workspace.
---
--- @param files string File.
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_API.add_files(files)

  log.trace("P4_File_API (add_files): Enter")

  local success = false

  if type(files) == "table" then

    local p4_file_list
    success, p4_file_list = create_p4_file_list(files)

    if success and p4_file_list then

      local P4_Command_Add = require("p4.core.lib.command.add")

      success = P4_Command_Add:new(p4_file_list:get_file_paths()):run()

      if success then
        notify("Files opened for add")

        log.fmt_debug("Files opened for add: %s", vim.join(files, ' '))
      end
    end
  else
    log.fmt_error("P4_File_API (add_files): Invalid parameter")
  end

  log.trace("P4_File_API (add_files): Exit")

  return success
end

--- Checks out the specified file in the current client workspace.
---
--- @param file string File.
--- @return boolean success Result of the function.
---
--- @async
--- @nodiscard
function P4_File_API.edit(file)
  log.trace("P4_File_API (edit): Enter")

  local success = false

  if type(file) == "string" then

    local p4_file
    success, p4_file = create_p4_file(file)

    if success and p4_file then

      local P4_Command_Edit = require("p4.core.lib.command.edit")

      success = P4_Command_Edit:new({file}):run()

      if success then
        notify("File opened for edit: " .. file)

        log.fmt_debug("File opened for edit: %s", file)
      end
    end
  else
    log.fmt_error("P4_File_API (edit): Invalid parameter")
  end

  log.trace("P4_File_API (edit): Exit")

  return success
end

--- Reverts the specified files in the current client workspace.
---
--- @param file string File.
---
--- @async
--- @nodiscard
function P4_File_API.revert(file)
  log.trace("P4_File_API (revert): Enter")

  local success = false

  if type(file) == "string" then
    local p4_file
    success, p4_file = create_p4_file(file)

    if success and p4_file then

      local P4_Command_Revert = require("p4.core.lib.command.revert")

      success = P4_Command_Revert:new({file}):run()

      if success then
        notify("File reverted: " .. file)

        log.fmt_debug("File reverted: %s", file)
      end
    end
  else
    log.fmt_error("P4_File_API (revert): Invalid parameter")
  end

  log.trace("P4_File_API (revert): Exit")

  return success
end

--- Shelves the specified files in the current client workspace.
---
--- @param file string File.
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
        notify("File shelved: " .. file)

        log.fmt_debug("File shelved: %s", file)
      end
    end
  else
    log.fmt_error("P4_File_API (shelve): Invalid parameter")
  end

  log.trace("P4_File_API (shelve): Exit")
end

--- Diffs the specified files in the current client workspace.
---
--- @param file string File.
---
--- @async
--- @nodiscard
function P4_File_API.diff(file)
  log.trace("P4_File_API (diff): Enter")

  local success = false

  if type(file) == "string" then
    local p4_file
    sucess, p4_file = create_p4_file(file)

    if success and p4_file then

    end
  else
    log.fmt_error("P4_File_API (diff): Invalid parameter")
  end

  log.trace("P4_File_API (diff): Exit")
end

return P4_File_API
