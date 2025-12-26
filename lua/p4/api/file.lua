local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_File_API
local P4_File_API = {}

--- Creates a P4 file from the specified file.
---
--- @param file string File.
--- @param is_add boolean True if we are adding the file.
--- @return P4_File? result Function result.
local function create_p4_file(file, is_add)

  local P4_File = require("p4.core.lib.file")

  ---@type P4_File_New
  local new_p4_file = {
    path = file,
    check_in_depot = true,
    get_stats = true,
  }

  ---@type P4_File?
  local p4_file = P4_File:new(new_p4_file)

  local success, in_depot = p4_file:get_in_depot()

  if success then

    if in_depot then
      log.fmt_debug("File in depot: %s", file)
    else
      log.fmt_error("File not in depot: %s", file)

      -- Handle the case where the file instance is a file that is going to be added to the depot.
      if not is_add then
        return nil
      end
    end
  end

  if success then
    success = p4_file:get_fstat()
  end

  if not success then
    p4_file = nil
  end

  return p4_file
end

--- Creates a P4 file list from the specified files.
---
--- @param files string[] One or more files.
--- @return P4_File_List? result Function result.
local function create_p4_file_list(files)

  local P4_File_List = require("p4.core.lib.file_list")

  ---@type P4_File_List_New
  local new_file_list = {
    paths = files,
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

    local p4_file = create_p4_file(file, true)

    if p4_file then

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

    local p4_file_list = create_p4_file_list(files)

    if p4_file_list then

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

    local p4_file = create_p4_file(file, false)

    if p4_file then

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

  local p4_file = create_p4_file(file, false)

  if p4_file then

    local P4_Command_Revert = require("p4.core.lib.command.revert")

    local success = P4_Command_Revert:new({file}):run()

    if success then
      notify("File reverted: " .. file)

      log.fmt_debug("File reverted: %s", file)
    end
  end

  log.trace("P4_File_API (revert): Exit")
end

--- Shelves the specified files in the current client workspace.
---
--- @param file string File.
---
--- @async
--- @nodiscard
function P4_File_API.shelve(file)
  log.trace("P4_File_API (shelve): Enter")

  local p4_file = create_p4_file(file, false)

  if p4_file then

    local P4_Command_Shelve = require("p4.core.lib.command.shelve")

    local success = P4_Command_Shelve:new({file}):run()

    if success then
      notify("File shelved: " .. file)

      log.fmt_debug("File shelved: %s", file)
    end
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

  local p4_file = create_p4_file(file, false)

  if p4_file then
    --TODO:
  end

  log.trace("P4_File_API (diff): Exit")
end

return P4_File_API
