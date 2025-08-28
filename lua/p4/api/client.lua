local nio = require("nio")

local log = require("p4.log")
local notify = require("p4.notify")

local p4_env = require("p4.core.env")

--- @class P4_Client_API
local P4_Client_API = {}

--- @class P4_Client_API_New_Options
--- @field template string Copies options and view from the specified template client.

--- Creates a new CL in the current client workspace.
---
--- @param client_name string P4 client name.
--- @param opts? P4_Client_API_New_Options Options.
--- @async
function P4_Client_API.new(client_name, opts)
  opts = opts or {}

  log.trace("P4_Client_API: new")

  -- Ensure the P4 environment is valid before we continue.
  if p4_env.check() then
    nio.run(function()
      local P4_Command_Client = require("p4.core.lib.command.client")

      --- @type P4_Command_Client_Options
      local cmd_opts = {
        type = P4_Command_Client.opts_type.READ,
      }

      -- Get options and review from the specified template.
      if opts.template then
        cmd_opts.read.template = opts.template
      end

      -- Create a new client and dump to stdout.
      local cmd = P4_Command_Client:new(client_name, cmd_opts)

      local success, sc = pcall(cmd:run().wait)

      --- @cast sc vim.SystemCompleted

      if success then
        vim.schedule(function()
          local buf = vim.api.nvim_create_buf(false, true)

          vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
          vim.api.nvim_set_option_value("filetype", "p4_spec", { buf = buf })

          -- CL name won't be assigned until the CL spec is written so
          -- we can't know what it is ahead of time.
          vim.api.nvim_buf_set_name(buf, "Client: " .. client_name)

          vim.api.nvim_buf_set_lines(buf, 0, 1, true, vim.split(sc.stdout, "\n"))

          vim.api.nvim_win_set_buf(0, buf)

          vim.api.nvim_create_autocmd("BufWriteCmd", {
            buffer = buf,
            once = true,
            callback = function()

              local client_spec = vim.api.nvim_buf_get_lines(buf, 0, -1, true)

              vim.api.nvim_buf_delete(buf, { force = true })

              nio.run(function()

                --- @type P4_Command_Client_Options
                cmd_opts = {
                  type = P4_Command_Client.opts_type.WRITE,
                  write = {
                    input = client_spec
                  },
                }

                cmd = P4_Command_Client:new(client_name, cmd_opts)

                success, sc = pcall(cmd:run().wait)

                if success then
                  notify("New Client spec written")

                  log.debug("Successfully written the new Client's spec")
                else
                  log.fmt_error("Failed to write the new Client's spec")
                end
              end)
            end,
          })
        end)
      end
    end)
  end
end

return P4_Client_API
