local log = require("p4.log")

local P4_Command = require("p4.core.lib.command")

-- Lua 5.1 compatibility

-- selene: allow(incorrect_standard_library_use)
if not table.unpack then
    table.unpack = unpack
end

--- @class P4_Command_Change_Read_Options : table

--- @class P4_Command_Change_Write_Options : table
--- @field input? string[] Write input.

--- @class P4_Command_Change_Options : table
--- @field cl? string Optional P4 CL name.
--- @field type P4_COMMAND_CHANGE_OPTS_TYPE Indicates the available options that may be used for the command.
--- @field read? P4_Command_Change_Read_Options Read options.
--- @field write? P4_Command_Change_Write_Options Write options.

--- @class P4_Command_Change_Result_Date_Time : table
--- @field date string Date
--- @field time string Time

--- @class P4_Command_Change_Result : table
--- @field output string Read change spec output.
--- @field change string CL change number
--- @field date P4_Command_Change_Result_Date_Time Last modified date
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

--- @class P4_Command_Change : P4_Command
--- @field opts P4_Command_Change_Options Command options.
local P4_Command_Change = {}

P4_Command_Change.__index = P4_Command_Change

setmetatable(P4_Command_Change, {__index = P4_Command})

--- @enum P4_COMMAND_CHANGE_OPTS_TYPE
P4_Command_Change.opts_type = {
    READ = 0,
    WRITE = 1,
}

--- Parses the output of the P4 command.
---
--- @param output string
--- @return P4_Command_Change_Result result Hold's the parsed result from the command output.
local function process_response(output)

  log.trace("P4_Command_Change: process_response")

  --- @type P4_Command_Change_Result
  local spec_table = {
    output = output,
    change = '',
    date = {
      date = '',
      time = '',
    },
    client = '',
    user = '',
    status = '',
    type = '',
    description = '',
    imported_by = '',
    identity = '',
    jobs = '',
    stream = '',
    files = {},
  }

  local spec = output

  if spec and string.len(spec) then

    -- Convert spec to table
    local spec_lines = vim.split(spec, "\n")

    local index = 1

    while index < #spec_lines do

      local end_index = 1

      -- If this is a spec field
      if string.match(spec_lines[index], "^%a+:") then

        -- If there are more lines
        if index + 1 ~= #spec_lines then

          -- selene: allow(incorrect_standard_library_use)
          local list = {table.unpack(spec_lines, index + 1)}

          end_index = index

          local index2 = 1

          -- Find end of the spec field. This may be the last line.
          while index2 < #list do

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

          after = string.gsub(after, "\t", " ")
          after = vim.trim(after)

          local key = string.lower(before)

          if key == "date" then

            local t = {}

            for string in string.gmatch(after, "[^%s]+") do
              table.insert(t, string)
            end

            spec_table[key] = {
              date = t[1],
              time = t[2],
            }

          elseif key == "files" then

            local tbl = {}

            for string in string.gmatch(after, "[^%s]+ [^%s]+ [^%s]+") do
              for string2 in string.gmatch(string, "[^%s]+") do
                table.insert(tbl, string2)
                break
              end
            end

            spec_table[key] = tbl
          else
            spec_table[key] = after
          end
        end

        -- Account for additional lines that were processed.
        index = end_index

      end

      index = index + 1
    end

  end

  log.fmt_debug("P4_Command_Change: Process Response result, %s", spec_table)

  return spec_table
end

--- Creates the P4 command.
---
--- @param opts? P4_Command_Change_Options P4 command options.
--- @return P4_Command_Change P4_Command_Change P4 command.
function P4_Command_Change:new(opts)
  opts = opts or {}

  log.trace("P4_Command_Change: new")

  local command = {
    "p4",
    "change",
  }

  if opts.type == P4_Command_Change.opts_type.READ then

    local ext_cmd = {
      "-o", -- Write change list to STDOUT
    }

    vim.list_extend(command, ext_cmd)
  end

  if opts.type == P4_Command_Change.opts_type.WRITE then
    local ext_cmd = {
      "-i", -- Read change list to STDIN
    }

    vim.list_extend(command, ext_cmd)
  end

  if opts.cl then
    table.insert(command, opts.cl)
  end

  --- @type P4_Command_Change
  local new = P4_Command:new(command)

  setmetatable(new, P4_Command_Change)

  new.opts = opts

  if opts.type == P4_Command_Change.opts_type.WRITE then
    assert(opts.write and opts.write.input, "Input required for P4 client command")

    -- Input needs to be supplied to STDIN.
    new.sys_opts["stdin"] = opts.write.input
  end

  return new
end

--- Runs the P4 command.
---
--- @return boolean success Indicates if the function was succesful.
--- @return P4_Command_Change_Result? Result Holds the result if the function was successful.
--- @async
function P4_Command_Change:run()

  local result = nil

  local success, sc = pcall(P4_Command.run(self).wait)

  if success then
    if self.opts.type == P4_Command_Change.opts_type.READ then
      result = process_response(sc.stdout)
    end
  end

  return success, result
end

return P4_Command_Change
