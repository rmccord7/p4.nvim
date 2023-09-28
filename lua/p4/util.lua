local function login(password, opts)
    opts = opts or {}

    return {
        "p4",
        "login",
        password,
    }
end

local M = {}

function M.print(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "P4" })
end

function M.warn(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = "P4" })
end

function M.error(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "P4" })
end

function M.debug(msg)
    local config = require("p4.config")

    if config.opts.debug then
        vim.notify(msg, vim.log.levels.DEBUG, { title = "P4" })
    end
end

function M.run_command(cmd)
    local result = vim.system(cmd,
    {
        text = true,
    }):wait()

    if result.code > 0 then
        M.error(result.stderr)

        -- If we failed because we are not logged in, then log in and re-run the command.
        if string.find(result.stderr, "Your session has expired, please login again.", 1, true) or
            string.find(result.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

            vim.fn.inputsave()
            local password = vim.fn.inputsecret("Password: ")
            vim.fn.inputrestore()

            result = vim.system(login(), { stdin = password }):wait()

            if result.code == 0 then
                result = vim.system(cmd,
                {
                    text = true,
                }):wait()

                if result.code > 0 then
                    M.error(result.stderr)
                end
            else
                util.error(result.stderr)
            end
        end
    end

    return result
end

return M
