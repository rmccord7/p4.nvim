local util = require("p4.util")

local M = {}

function M.run(cmd)
  if type(cmd) == 'table' then

      local result = vim.system(cmd,
      {
          text = true,
      }):wait()

      if result.code > 0 then
          util.error(result.stderr)

          -- If we failed because we are not logged in, then log in and re-run the command.
          if string.find(result.stderr, "Your session has expired, please login again.", 1, true) or
             string.find(result.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

              vim.fn.inputsave()
              local password = vim.fn.inputsecret("Password: ")
              vim.fn.inputrestore()

              result = vim.system({"p4", "login"}, { stdin = password }):wait()

              if result.code == 0 then
                  result = vim.system(cmd,
                  {
                      text = true,
                  }):wait()

                  if result.code > 0 then
                      util.error(result.stderr)
                  end
              else
                  util.error(result.stderr)
              end
          end
      end

      return result
    end
end

return M
