local shell = require("p4.core.shell")

local p4_file_cmds = require("p4.core.commands.file")

local file = {}

--- Makes the current buffer writeable.
local function set_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", false, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", true, { scope = "local" })
end

--- Makes the current buffer read only.
local function clear_buffer_writeable()
  vim.api.nvim_set_option_value("readonly", true, { scope = "local" })
  vim.api.nvim_set_option_value("modifiable", false, { scope = "local" })
end

--- Adds one or more files to the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function file.add(file_paths, opts)
  opts = opts or {}

  -- Get all file information from the P4 server.
  local file_info_list = file.get_info(file_paths)

  if file_info_list then

    -- TODO: Remove file path if file is already opened for add. P4 command
    -- to add a file will catch it, but we can just silently reduce messages.

    -- Add the file to the client workspace.
    result = shell.run(p4_file_cmds.add(file_paths))

    if result.code == 0 then

      set_buffer_writeable()
    end
  end
end

--- Checks out one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function file.edit(file_paths, opts)
  opts = opts or {}

  -- Get all file information from the P4 server.
  local file_info_list = file.get_info(file_paths)

  if file_info_list then

    -- TODO: Remove file path if file is already opened for edit. P4 command
    -- to edit a file will catch it, but we can just silently reduce messages.

   local result = shell.run(p4_file_cmds.edit(file_paths))

   if result.code == 0 then

     set_buffer_writeable()
   end
 end
end

--- Reverts one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function file.revert(file_paths, opts)
  opts = opts or {}

  local result = shell.run(p4_file_cmds.revert(file_paths, opts))

  if result.code == 0 then

    vim.cmd("edit")

    -- File was opened for edit so make buffer read only and not
    -- modifiable
    clear_buffer_writeable()
  end
end

--- Shelves one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
function file.shelve(file_paths, opts)
  opts = opts or {}

  shell.run(p4_file_cmds.shelve(file_paths, opts))
end

--- Gets information for one or more files in the client workspace.
---
--- @param file_paths string|string[] One or more files.
---
--- @param opts? table Optional parameters. Not used.
---
--- @return P4_Fstat? fstat File information
function file.get_info(file_paths, opts)
  opts = opts or {}

  local files = {}
  local info = {}

  local result = shell.run(p4_file_cmds.fstat(file_paths, opts))

  if result.code == 0 then

    for _, line in ipairs(vim.split(result.stdout, "\n")) do

      if line ~= "" then

        -- File is not in workspace.
        if string.find(line, "no such file(s).", 1, true) then

          -- NOTE: Possible file does not exist, but if
          -- this is for a new file that exists then the
          -- p4 command to do the subsequent add will fail.

          -- Just add an empty entry so the caller can continue.
          info = {}

        -- File is not in root or client view.
        elseif string.find(line, "file(s) not in client view.", 1, true) or
               string.find(line, "is not under client's root", 1, true) then

          -- Fail.
          files = nil
          break

        -- Valid file info has been returned.
        else

          local t = vim.split(line)

          if t[1] == "..." then

            -- Only store level one values for now.
            if t[2] ~= "..." then
              info[t[2]] = t[3]
            end
          end

          -- P4 fstat key isMapped doesn't have value so just set it to true.
          info.isMapped = true

        end
      else
        -- Don't include last line as empty table
        if not vim.tbl_isempty(info) then
          table.insert(files, info)
          info = {}
        end
      end
    end

  else
     -- Fail.
    files = nil
  end

  return files
end
return file
