local file_cmds = require("p4.core.commands.file")

--- @class P4_File
--- @field fstat P4_Fstat P4 files stats

--- P4 file
local file = {}

--- Creates a new CL
function file.new(file_path)

  setmetatable({}, file)

  local new_file = {}

  new_file.fstat = file_cmds.get_info(file_path)

  if vim.tbl_isempty(new_file.fstat) then
    log.error("P4 file stat failed")
    return nil
  end

  return new_file
end


return file

