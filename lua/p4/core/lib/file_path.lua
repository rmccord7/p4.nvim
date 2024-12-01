local log = require("p4.log")

--- @class P4_Path : table
--- @field type P4_PATH_TYPE P4 file path type.
--- @field path string File path.

--- @class P4_File_Path : table
--- @field private depot_valid boolean Indicates tha the P4 depot file path is valid.
--- @field private depot string P4 depot file path.
--- @field private client_valid boolean Indicates tha the P4 client file path is valid.
--- @field private client string P4 client file path.
--- @field private host_valid boolean Indicates tha the P4 local file path is valid.
--- @field private host string P4 local file path (can't use local keyword).
local P4_File_Path = {}

--- @enum P4_PATH_TYPE
P4_File_Path.type = {
  DEPOT = 0,
  CLIENT = 1,
  HOST = 2, -- Can't use local keyword
}

--- Creates a new P4 path.
---
--- @param p4_path P4_Path P4 path.
--- @return P4_File_Path P4_File_Path A new P4 file path.
--- @nodiscard
function P4_File_Path:new(p4_path)

  log.trace("P4_File_Path: new")

  P4_File_Path.__index = P4_File_Path

  local new = setmetatable({}, P4_File_Path)

  new.depot_valid = false
  new.depot = ''
  new.client_valid = false
  new.client = ''
  new.host_valid = false
  new.host = ''

  if p4_path.type == P4_File_Path.type.DEPOT then
    new.depot_valid = true
    new.depot = p4_path.path
  elseif p4_path.type == P4_File_Path.type.CLIENT then
    new.client_valid = true
    new.client = p4_path.path
  else
    new.host_valid = true
    new.host = p4_path.path
  end

  new:check()

  return new
end

--- Checks to make sure the P4 file path is valid.
function P4_File_Path:check()

  log.trace("P4_File_Path: check")

  local function check_path(path)
    return (path.depot_valid and path.depot:len() > 0  and true or false) or
           (path.client_valid and path.client:len() > 0  and true or false) or
           (path.host_valid and path.host:len() > 0 and true or false)
  end

  assert(check_path(self), "At least one P4 file path must be valid")
end

--- Gets the P4 file path.
---
--- @return string result P4 file path.
function P4_File_Path:get_file_path()

  log.trace("P4_File_Path: get_file_path")

  -- Prefer local file path.
  if self.host_valid then
    return self.host
  end

  -- Next depot file path.
  if self.depot_valid then
    return self.depot
  end

  -- Last client file path.
  if self.client_valid then
    return self.client
  end

  return "Unknown"
end

--- Updates the P4 file paths.
---
--- @param p4_path_list P4_Path[] P4 file paths.
function P4_File_Path:update_file_paths(p4_path_list)

  log.trace("P4_File_Path: update_file_paths")

  for _, p4_path in ipairs(p4_path_list) do

    if p4_path.type == P4_File_Path.type.DEPOT then
      self.depot_valid = true
      self.depot = p4_path.path
    elseif p4_path.type == P4_File_Path.type.CLIENT then
      self.client_valid = true
      self.client = p4_path.path
    else
      self.host_valid = true
      self.host = p4_path.path
    end

    self:check()
  end
end

return P4_File_Path
