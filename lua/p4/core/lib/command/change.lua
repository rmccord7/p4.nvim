log = require("p4.log")

-- Lua 5.1 compatibility
if not table.unpack then
    table.unpack = unpack
end

--- @class P4_CL_Spec_Date_Time : table
--- @field Date string Date
--- @field Time string Time

--- @class P4_CL_Spec : table
--- @field change integer CL change number
--- @field date P4_CL_Spec_Date_Time Last modified date
--- @field client string Name of client that owns the CL
--- @field user string User that owns the CL
--- @field status string Either 'pending' or 'submitted'.
--- @field type string Either 'public' or 'restricted'.
--- @field description string CL description
--- @field imported_by string CL description
--- @field identity string CL description
--- @field jobs string CL description
--- @field stream string CL description
--- @field files table List of files checked out for this CL

--- @class P4_Command_Change_Options : table
--- @field read boolean Indicates if the change list is read or written.

--- @class P4_Command_Change_Result : P4_CL_Spec

--- @class P4_Command_Change : P4_Command
--- @field opts P4_Command_Change_Options Command options.
local P4_Command_Change = {}

--- Creates the P4 command.
---
--- @param cl? string Optional P4 CL name.
--- @param opts? P4_Command_Change_Options P4 command options.
--- @return P4_Command_Change P4_Command_Change P4 command.
function P4_Command_Change:new(cl, opts)
  opts = opts or {}

  log.trace("P4_Command_Change: New")

  P4_Command_Change.__index = P4_Command_Change

  local P4_Command = require("p4.core.lib.command")

  setmetatable(P4_Command_Change, {__index = P4_Command})

  local command = {
    "p4",
    "change",
  }

  if opts.read then

    local ext_cmd = {
      "-o", -- Write change list to STDOUT
    }

    vim.list_extend(command, ext_cmd)
  else
    local ext_cmd = {
      "-i", -- Read change list to STDIN
    }

    vim.list_extend(command, ext_cmd)
  end

  if cl then
    table.insert(command, cl)
  end

  --- @type P4_Command_Change
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Change)

  new.opts = opts

  return new
end

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Change_Result result Hold's the parsed result from the command output.
function P4_Command_Change:process_response(output)

  log.trace("P4_Command_Change: Process Response")

  --- @type P4_Command_Change_Result
  local spec_table = {}

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

        vim.print(vim.inspect({table.unpack(spec_lines, index, end_index)}))

        -- Convert spec field to a string
        local spec_field = table.concat(spec_lines, ' ', index, end_index)

        -- Add spec field to the spec table
        local pos = string.find(spec_field,":")

        if pos then
          local before = string.sub(spec_field, 1, pos - 1)
          local after = string.sub(spec_field, pos + 1)

          after = string.gsub(after, "\t", " ")
          after = vim.trim(after)

          spec_table[string.lower(before)] = after

          print(vim.inspect(string.lower(before)))
        end

        -- Account for additional lines that were processed.
        index = end_index

      end

      index = index + 1
    end

  end

  local key

  key = "date"

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

  key = "files"

  if spec_table[key] then

    local tbl = {}

    for string in string.gmatch(spec_table[key], "[^%s]+ [^%s]+ [^%s]+") do
      for string2 in string.gmatch(string, "[^%s]+") do
        table.insert(tbl, string2)
        break
      end
    end

    spec_table[key] = tbl
  end

  log.fmt_debug("P4_Command_Change: Process Response result, %s", spec_table)

  return spec_table
end

return P4_Command_Change
