local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

-- Lua 5.1 compatibility
if not table.unpack then
    table.unpack = unpack
end

--- @class P4_Client_Spec_Date_Time : table
--- @field Date string Date
--- @field Time string Time

--- @class P4_Client_Spec_View : table
--- @field Depot string Deport view mapping
--- @field Workspace string Workspace view mapping

--- @class P4_Client_Spec : table
--- @field output string Read change spec output.
--- @field client string Name of the client
--- @field update P4_Client_Spec_Date_Time Date/time this client was modified
--- @field access P4_Client_Spec_Date_Time Date/time this client was last used
--- @field owner string User that owns the client
--- @field host string Host that owns the client
--- @field description string Client description
--- @field root string Base directory for client workspace
--- @field alt_root table Up to two alternate client roots
--- @field options string Client options
--- @field submit_options string Submit options for the workspace
--- @field line_end string Text file line endings on the client
--- @field view P4_Client_Spec_View[] Lines to map depot files to the current workpace

--- @class P4_Command_Client_Read_Options : table
--- @field template string Copies options and view from the specified template client.

--- @class P4_Command_Client_Write_Options : table
--- @field input? string[] Write input.

--- @class P4_Command_Client_Options : table
--- @field type P4_COMMAND_CLIENT_OPTS_TYPE Indicates the available options that may be used for the command.
--- @field read? P4_Command_Client_Read_Options Read options.
--- @field write? P4_Command_Client_Write_Options Write options.

--- @class P4_Command_Client_Result : P4_Client_Spec

--- @class P4_Command_Client : P4_Command
--- @field client string P4 client name.
--- @field opts P4_Command_Client_Options Command options.
local P4_Command_Client = {}

P4_Command_Client.__index = P4_Command_Client

setmetatable(P4_Command_Client, {__index = P4_Command})

--- @enum P4_COMMAND_CLIENT_OPTS_TYPE
P4_Command_Client.opts_type = {
    READ = 0,
    WRITE = 1,
}

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Client_Result result Hold's the parsed result from the command output.
local function process_response(output)

  log.trace("P4_Command_Client: process_response")

  --- @type P4_Command_Client_Result
  local spec_table = {
    output = output,
  }

  local spec = output

  if spec and string.len(spec) then

    -- Convert spec to table
    local spec_lines = vim.split(spec, "\n")

    local index = 1

    while (index < #spec_lines) do

      local end_index = 1

      -- If this is a spec field
      if string.match(spec_lines[index], "^%a+:") then

        -- If there are more lines
        if index + 1 ~= #spec_lines then

          -- Start search at next line
          local list = {table.unpack(spec_lines, index + 1)}

          end_index = index

          local index2 = 1

          -- Find end of the spec field. This may be the last line.
          while (index2 < #list) do

            -- If we find a spec field then the previous line marks the
            -- the last line of the current spec field.
            if string.match(list[index2], "^%a+:") then
              end_index = end_index - 1
              index2 = index2 - 1
              break;
            end

            end_index = end_index + 1
            index2 = index2 + 1
          end
        end

        -- Convert spec field to a string
        local spec_field = table.concat(spec_lines, ' ', index, end_index)

        -- Add spec field to the spec table
        local pos = string.find(spec_field,":")

        if pos then
          local before = string.sub(spec_field, 1, pos - 1)
          local after = string.sub(spec_field, pos + 1)

          after = string.gsub(after, "\t", "")
          after = vim.trim(after)

          spec_table[string.lower(before)] = after
        end

        -- Account for additional lines that were processed.
        index = end_index

      end

      index = index + 1
    end

  end

  local key

  key = "access"

  if spec_table[key] then

    local tbl = {}

    for string in string.gmatch(spec_table[key], "[^%s]+") do
      table.insert(tbl, string)
    end

    spec_table[key] = {
      date = tbl[1],
      time = tbl[2],
    }
  end

  key = "update"

  if spec_table[key] then

    local tbl = {}

    for string in string.gmatch(spec_table[key], "[^%s]+") do
      table.insert(tbl, string)
    end

    spec_table[key] = {
      date = tbl[1],
      time = tbl[2],
    }
  end

  key = "view"

  if spec_table[key] then

    local view = {}
    local tbl = {}

    for string in string.gmatch(spec_table[key], "[^%s]+ [^%s]+") do

      local tmp = {}

      for string2 in string.gmatch(string, "[^%s]+") do
        table.insert(tmp, string2)
      end

      tbl = {
        depot = tmp[1],
        workspace = tmp[2],
      }

      table.insert(view, tbl)
    end

    spec_table[key] = view
  end

  return spec_table
end

--- Creates the P4 command.
---
--- @param client string P4 client name.
--- @param opts? P4_Command_Client_Options P4 command options.
--- @return P4_Command_Client P4_Command_Client P4 command.
function P4_Command_Client:new(client, opts)
  opts = opts or {}

  log.trace("P4_Command_Client: new")

  local command = {
    "client",
  }

  if opts.type == P4_Command_Client.opts_type.READ then

    local ext_cmd = {
      "-o", -- Read client spec to STDOUT
    }

    vim.list_extend(command, ext_cmd)

    if opts.read and opts.read.template then

      ext_cmd = {
        "-t", -- Get options and view from the specified template for the new client.
        opts.read.template
      }

      vim.list_extend(command, ext_cmd)
    end
  end

  if opts.type == P4_Command_Client.opts_type.WRITE then

    local ext_cmd = {
      "-i", -- Write client spec to STDIN
    }

    vim.list_extend(command, ext_cmd)
  end

  table.insert(command, client)

  ---@type P4_Command_New
  local info = {
    command = command,
    name = command[1],
    global_opts = {
      json = false,
    }
  }

  --- @type P4_Command_Client
  local new = P4_Command:new(info)

  setmetatable(new, P4_Command_Client)

  new.opts = opts
  new.client = client

  if opts.type == P4_Command_Client.opts_type.WRITE then
    assert(opts.write and opts.write.input, "Input required for P4 client command")

    -- Input needs to be supplied to STDIN.
    new.sys_opts["stdin"] = opts.write.input
  end

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Client_Result|nil Result Holds the result if the function was successful.
--- @async
function P4_Command_Client:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    result = process_response(sc.stdout)
  end

  return success, result
end

return P4_Command_Client
