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

local cl_spec = {}

--- Parses a P4 CL spec
---
--- @param spec string? CL spec
--- @return P4_CL_Spec parsed_spec Parsed P4 client spec
function cl_spec.parse(spec)

  local spec_table = {}

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

            if string.len(list[index2]) == 0 then
              break;
            end

            end_index = end_index + 1
            index2 = index2 + 1
          end
        end

        -- vim.print(vim.inspect({table.unpack(spec_lines, index, end_index)}))

        -- Convert spec field to a string
        local spec_field = table.concat(spec_lines, ' ', index, end_index)

        -- Add spec field to the spec table
        local pos = string.find(spec_field,":")

        if pos then
          local before = string.sub(spec_field, 1, pos - 1)
          local after = string.sub(spec_field, pos + 1)

          after = string.gsub(after, "\t", "")
          after = vim.trim(after)

          spec_table[before] = after
        end

        -- Account for additional lines that were processed.
        index = end_index

      end

      index = index + 1
    end

  end

  local key

  key = "Date"

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

  key = "Files"

  if spec_table[key] then

    local tbl = {}

    for string in string.gmatch(spec_table[key], "[^%s]+") do
      table.insert(tbl, string)
    end

    spec_table[key] = tbl

  end

  -- vim.print(vim.inspect(spec_table))
  log.fmt_debug("%s", spec_table)

  return spec_table
end

return cl_spec
