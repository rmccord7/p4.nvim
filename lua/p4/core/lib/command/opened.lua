local log = require("p4.log")

--- @class P4_Command_Opened_Options : table
--- @field cl? string Only files in the specified changelist.

--- @class P4_Command_Opened_Result : table
--- @field depot_path string P4 depot file path.
--- @field cl string P4 CL.

--- @class P4_Command_Opened : P4_Command
--- @field opts P4_Command_Opened_Options Command options.
local P4_Command_Opened = {}

--- Creates the P4 command.
---
--- @param opts? P4_Command_Opened_Options P4 command options
--- @return P4_Command_Opened P4_Command_Opened A new current P4 client
function P4_Command_Opened:new(opts)
  opts = opts or {}

  P4_Command_Opened.__index = P4_Command_Opened

  local P4_Command = require("p4.core.lib.command")

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

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Opened_Result[] result Hold's the parsed result from the command output.
function P4_Command_Opened:process_response(output)
  --- @type P4_Command_Opened_Result[]
  local result = {}

  for _, line in ipairs(vim.split(output, "\n", {trimempty = true})) do

    local chunks = {}
    for substring in line:gmatch("%S+") do
      table.insert(chunks, substring)
    end

    --- @type P4_Command_Opened_Result
    local file_info = {
      depot_path = vim.split(chunks[1], '#')[1],
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

return P4_Command_Opened
