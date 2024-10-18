local M = {}

function M.split_str(str, sep)
  sep = sep or "%s"

  local t = {}
  for string in string.gmatch(str, "([^"..sep.."]+)") do
    table.insert(t, string)
  end

  return t
end

return M
