local shell_log = require("p4.core.shell_log")

vim.api.nvim_create_user_command(
  "P4CLog",
  function()
    vim.cmd(([[tabnew %s]]):format(shell_log.outfile))
  end,
  {
    desc = "Opens the p4 command log.",
  }
)

local M = {}

function M.run(cmd)
  local log = require("p4.core.log")

  if type(cmd) == 'table' then

      shell_log.command(table.concat(cmd, ' '))

      local result = vim.system(cmd,
      {
          text = true,
      }):wait()

      if result.code == 0 then
          if string.len(result.stdout) ~= 0 then
            shell_log.output(result.stdout)
          end
          if string.len(result.stderr) ~= 0 then
            shell_log.error(result.stderr)
          end
      else
          shell_log.error(result.stderr)

          -- If we failed because we are not logged in, then log in and re-run the command.
          if string.find(result.stderr, "Your session has expired, please login again.", 1, true) or
             string.find(result.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

              vim.fn.inputsave()
              local password = vim.fn.inputsecret("Password: ")
              vim.fn.inputrestore()

              shell_log.command(table.concat({"p4", "login"}, ' '))

              result = vim.system({"p4", "login"}, { stdin = password }):wait()

              if result.code == 0 then

                  if string.len(result.stdout) ~= 0 then
                    shell_log.output(result.stdout)
                  end
                  if string.len(result.stderr) ~= 0 then
                    shell_log.error(result.stderr)
                  end

                  shell_log.command(table.concat(cmd, ' '))

                  -- Re-run previous command
                  result = vim.system(cmd,
                  {
                      text = true,
                  }):wait()

                  if result.code == 0 then
                    if string.len(result.stdout) ~= 0 then
                      shell_log.output(result.stdout)
                    end
                    if string.len(result.stderr) ~= 0 then
                      shell_log.error(result.stderr)
                    end
                  else
                      shell_log.error(result.stderr)
                  end
              else
                  shell_log.error(result.stderr)
              end
          end
      end

      return result
  else
    log.fmt_error("Invalid shell command type: %s", cmd)
  end
end

return M
