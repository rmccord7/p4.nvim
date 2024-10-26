log = require("p4.log")

--
-- Client: eds_win
-- Owner:  edk
-- Description:
--         Ed's Windows Workspace
-- Root:   null
-- Options:        nomodtime noclobber
-- SubmitOptions:  submitunchanged
-- View:
--         //depot/main/...     "//eds_win/c:/Current Release/..."
--         //depot/rel1.0/...   //eds_win/d:/old/rel1.0/...
--         //depot/rel2.0/...   //eds_win/d:/old/rel2.0/...

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

local client_spec = {}

--- Parses a P4 client spec
---
--- @param spec string? Client spec
--- @return P4_Client_Spec parsed_spec Parsed P4 client spec
function client_spec.parse(spec)

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

  key = "Access"

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

  key = "Update"

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

  key = "View"

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

  -- vim.print(vim.inspect(spec_table))
  log.fmt_debug("%s", spec_table)

  return spec_table
end

return client_spec
