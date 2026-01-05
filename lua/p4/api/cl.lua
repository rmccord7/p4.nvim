local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_CL_API
local P4_CL_API = {}

--- Creates a new CL.
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_CL_API.new()
  log.trace("P4_CL_API (new): Enter")

  local P4_Command_Change = require("p4.core.lib.command.change")

  --- @type P4_Command_Change_Options
  local cmd_opts = {
    cl = nil,
    type = P4_Command_Change.opts_type.READ,
    read = nil,
  }

  -- Create a new CL and dump to stdout.
  local success, result = P4_Command_Change:new(cmd_opts):run()

  --- @cast result P4_Command_Change_Result

  if success then
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
    vim.api.nvim_set_option_value("filetype", "p4_spec", { buf = buf })

    -- CL name won't be assigned until the CL spec is written so
    -- we can't know what it is ahead of time.
    vim.api.nvim_buf_set_name(buf, "CL: New")

    vim.api.nvim_buf_set_lines(buf, 0, 1, true, vim.split(result.output, "\n"))

    vim.api.nvim_win_set_buf(0, buf)

    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      once = true,
      callback = function()

        local cl_spec = vim.api.nvim_buf_get_lines(buf, 0, -1, true)

        vim.api.nvim_buf_delete(buf, { force = true })

        --- @type P4_Command_Change_Options
        cmd_opts = {
          cl = nil,
          type = P4_Command_Change.opts_type.WRITE,
          write = {
            input = cl_spec
          },
        }

        cmd = P4_Command_Change:new(cmd_opts)

        success, _ = P4_Command_Change:new(cmd_opts):run()
      end,
    })
  end

  log.trace("P4_CL_API (new): Exit")

  return success
end

--- Reverts a CL.
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_CL_API.revert()
  log.trace("P4_CL_API (revert): Enter")

  notify("Not supported", vim.log.level.ERROR);

  log.trace("P4_CL_API (revert): Exit")

  return false
end

--- Shelves a CL's files.
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_CL_API.shelve_files()
  log.trace("P4_CL_API (shelve_files): Enter")

  notify("Not supported", vim.log.level.ERROR);

  log.trace("P4_CL_API (shelve_files): Exit")

  return false
end

--- Deletes a CLs shelved files.
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_CL_API.delete_shelved_files()
  log.trace("P4_CL_API (delete_shelve_files): Enter")

  notify("Not supported", vim.log.level.ERROR);

  log.trace("P4_CL_API (delete_shelve_files): Exit")

  return false
end

--- Deletes a CL
---
--- @return boolean success True if this function is successful.
---
--- @async
--- @nodiscard
function P4_CL_API.delete()
  log.trace("P4_CL_API (delete): Enter")

  notify("Not supported", vim.log.level.ERROR);

  log.trace("P4_CL_API (delete): Exit")

  return false
end

return P4_CL_API
