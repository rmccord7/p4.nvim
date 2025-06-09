local settings = require("p4.config")

local config = {
  name = "command", -- Name of the plugin. Prepended to log messages.
  use_console = vim.env.P4_SHELL_VERBOSE_LOGS == "1", -- Determines whether console logging is enabled.
  highlights = true, -- Determines if highlighting is enabled in console logging (using echohl).
  use_file = true, -- Determines whether file logging is enabled.

  -- Level configuration
  modes = {
    { name = "command", hl = "Comment", level = vim.log.levels.INFO },
    { name = "output", hl = "Comment", level = vim.log.levels.INFO },
    { name = "error", hl = "ErrorMsg", level = vim.log.levels.ERROR },
  },
}

local log = {
  outfile = vim.fs.joinpath(
    (vim.fn.has "nvim-0.10.0" == 1) and vim.fn.stdpath "log" or vim.fn.stdpath "cache",
    ("p4_%s.log"):format(config.name))
}

do
  local round = function(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
  end

  local tbl_has_tostring = function(tbl)
    local mt = getmetatable(tbl)
    return mt and mt.__tostring ~= nil
  end

  local make_string = function(...)
    local t = {}
    for i = 1, select("#", ...) do
      local x = select(i, ...)

      if type(x) == "number" and config.float_precision then
        x = tostring(round(x, config.float_precision))
      elseif type(x) == "table" and not tbl_has_tostring(x) then
        x = vim.inspect(x)
      else
        x = tostring(x)
      end

      t[#t + 1] = x
    end
    return table.concat(t, " ")
  end

  local log_at_level = function(level_config, message_maker, ...)

    -- Return early if we're below the current_log_level
    if level_config.level < settings.opts.log_level then
      return
    end
    local nameupper = level_config.name:upper()

    local msg = message_maker(...)
    local info = debug.getinfo(config.info_level or 2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    if config.use_console then
      local log_to_console = function()
        local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date "%H:%M:%S", lineinfo, msg)

        if config.highlights and level_config.hl then
          vim.cmd(string.format("echohl %s", level_config.hl))
        end

        local split_console = vim.split(console_string, "\n")
        for _, v in ipairs(split_console) do
          local formatted_msg = string.format("[%s] %s", config.name, vim.fn.escape(v, [["\]]))

          local ok = pcall(vim.cmd, string.format([[echom "%s"]], formatted_msg))
          if not ok then
            vim.api.nvim_out_write(msg .. "\n")
          end
        end

        if config.highlights and level_config.hl then
          vim.cmd "echohl NONE"
        end
      end
      if config.use_console == "sync" and not vim.in_fast_event() then
        log_to_console()
      else
        vim.schedule(log_to_console)
      end
    end

    -- Output to log file
    if config.use_file then
      local fp = assert(io.open(log.outfile, "a"))
      local str = string.format("[%-6s %s]: \n%s\n\n", nameupper, os.date(), msg)
      fp:write(str)
      fp:close()
    end
  end

  for _, x in ipairs(config.modes) do

    log[x.name] = function(...)
      return log_at_level(x, make_string, ...)
    end
  end
end

return log
