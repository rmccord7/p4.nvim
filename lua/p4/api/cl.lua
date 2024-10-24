local log = require("p4.core.log")

local cl_cmds = require("p4.core.commands.cl")

--- @class P4_CL
--- @field default boolean Indicates if this is the default CL
--- @field num integer CL number if this is not the default CL
--- @field client string Name of the client that is associated with this CL
--- @field files string[] List of files checked out for this CL
local cl = {
  name = 0,
  num = 0,
  client = '',
  files = {},
}

cl.__index = cl

--- Cleans up the CL's file list
local function cleanup_files(self)
  for file in pairs (self.files) do
    self.files[file] = nil
  end
end

--- Creates a new CL
function cl:new(num)
  local new_cl = {}
  setmetatable(self, cl)

  new_cl.num = num

  return new_cl
end

--- Edits the CL spec
function cl:edit_spec(buf)

  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "conf", { buf = buf })
  vim.api.nvim_set_option_value("expandtab", false, { buf = buf })

  vim.api.nvim_buf_set_name(buf, "change list: " .. self.num)

  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    once = true,
    callback = function()
      local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      result = vim.system(cl_cmds.write(self.num), { stdin = content }):wait()

      if result.code > 0 then
        log.error(result.stderr)
        return
      end

      vim.api.nvim_buf_delete(buf, { force = true })
    end,
  })
end

--- Get files from CL spec
function cl:get_files_from_spec(spec)

  local result

  -- Delete old files list
  cleanup_files(self)

  for index, line in ipairs(vim.split(spec, "\n")) do

    -- Files in the changelist begin with '#'
    if line:find("#", 1, true) then

      -- CL spec lists files in depot path
      local depot_path = line:sub(1, line:find("#", 1, true) - 1)

      result = log.run_command(cl_cmds.where(depot_path))

      if result.code == 0 then

        -- Result contains "depot_path client_path file_path"
        local path = {}

        -- Convert to table
        for string in result.stdout:gmatch("%S+") do
          table.insert(path, string)
        end

        -- Third element contains the file path
        table.insert(self.files, index, path[3])
      end
    end
  end
end
