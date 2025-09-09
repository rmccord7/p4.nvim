local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

--- @class P4_Command_Opened_Options : table
--- @field cl? string Only files in the specified changelist.

--- @class P4_Command_Opened_Result : table
--- @field path P4_Depot_File_Path P4 depot file path.
--- @field cl string P4 CL.

--- @class P4_Command_Opened : P4_Command
--- @field opts P4_Command_Opened_Options Command options.
local P4_Command_Opened = {}

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Opened_Result[] result Hold's the parsed result from the command output.
function P4_Command_Opened:_process_response(output)

  log.trace("P4_Command_Opened: process_response")

  --- @type P4_Command_Opened_Result[]
  local result = {}

  for _, line in ipairs(vim.split(output, "\n", {trimempty = true})) do

    local chunks = {}
    for substring in line:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    --- @type P4_Command_Opened_Result
    local file_info = {
      path = vim.split(chunks[1], '#')[1],
      cl = chunks[5],
    }

    -- Output swaps order 'default change' vs 'change XXXXXXXXX'
    if chunks[5] == "default" then
      file_info.cl = "default"
    end

    table.insert(result, file_info)
  end

  return result
end

--- Creates the P4 command.
---
--- @param opts? P4_Command_Opened_Options P4 command options
--- @return P4_Command_Opened P4_Command_Opened A new current P4 client
function P4_Command_Opened:new(opts)
  opts = opts or {}

  log.trace("P4_Command_Opened: new")

  P4_Command_Opened.__index = P4_Command_Opened

  setmetatable(P4_Command_Opened, {__index = P4_Command})

  local command = {
    "p4",
    "opened",
  }

  if opts.cl then

    local ext_cmd = {
      "-c",
      opts.cl,
    }

    vim.list_extend(command, ext_cmd)
  end

  --- @type P4_Command_Opened
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Opened)

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Opened_Result[]|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_Opened:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = P4_Command_Opened:_process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Opened
