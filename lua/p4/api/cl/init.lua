local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

--- @class P4_CL_API
local P4_CL_API = {}

--- Creates a new CL in the current client workspace.
function P4_CL_API.new()

  log.trace("CL API: New CL")

  nio.run(function()
    local P4_Command_Change = require("p4.core.lib.command.change")

    --- @type P4_Command_Change_Options
    local cmd_opts = {
      read = true,
    }

    -- Create a new CL and dump to stdout.
    local cmd = P4_Command_Change:new(nil, cmd_opts)

    local success, sc = pcall(cmd:run().wait)

    --- @cast sc vim.SystemCompleted

    if success then
      vim.schedule(function()
        local buf = vim.api.nvim_create_buf(false, true)

        vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
        vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
        vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

        -- CL name won't be assigned until the CL spec is written so
        -- we can't know what it is ahead of time.
        vim.api.nvim_buf_set_name(buf, "CL: New")

        vim.api.nvim_buf_set_lines(buf, 0, 1, true, vim.split(sc.stdout, "\n"))

        vim.api.nvim_win_set_buf(0, buf)

        vim.api.nvim_create_autocmd("BufWriteCmd", {
          buffer = buf,
          once = true,
          callback = function()

            local cl_spec = vim.api.nvim_buf_get_lines(buf, 0, -1, true)

            vim.api.nvim_buf_delete(buf, { force = true })

            nio.run(function()

              cmd = P4_Command_Change:new(nil)

              cmd.sys_opts["stdin"] = cl_spec

              success, sc = pcall(cmd:run().wait)

              if success then
                notify("New CL spec written")

                log.debug("Successfully written the new CL's spec")
              else
                log.fmt_error("Failed to write the new CL's spec")
              end
            end)
          end,
        })
      end)
    end
  end)
end

return P4_CL_API
