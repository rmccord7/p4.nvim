-- https://github.com/williamboman/mason.nvim/blob/main/lua/mason-core/path.lua
-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L209

local uv = vim.loop

local M = {}

local is_windows = uv.os_uname().version:match 'Windows'

local sep = (function()
    return string.sub(package.config, 1, 1)
end)()

-- Concatenates the specified file paths.
--- @param paths string[]
--- @return string
function M.concat(paths)
    return table.concat(paths, sep)
end

-- Returns if the specific path is a sub-directory.
--- @path root_path string
--- @path path string
--- @return boolean
function M.is_subdirectory(root_path, path)
    return root_path == path or path:sub(1, #root_path + 1) == root_path .. sep
end

-- Returns a path with Windows absolute path prefix to upper case
-- and Windows path seperators converted to Linux format.
--- @path path string
--- @return string
function M.sanitize(path)
  if is_windows then
    path = path:sub(1, 1):upper() .. path:sub(2)
    path = path:gsub('\\', '/')
  end
  return path
end

-- Returns a path with wildcard characters escaped.
--- @path path string
--- @return string
function M.escape_wildcards(path)
  return path:gsub('([%[%]%?%*])', '\\%1')
end

-- Returns if the specified path exists.
--- @path path string
--- @return boolean
function M.exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type or false
end

-- Returns if the specified path is a directory.
--- @path path string
--- @return boolean
function M.is_dir(path)
  return M.exists(path) == 'directory'
end

-- Returns if the specified path is a file.
--- @path path string
--- @return boolean
function M.is_file(path)
  return M.exists(path) == 'file'
end

-- Returns if the specified path is the file system root.
--- @path path string
--- @return boolean
function M.is_fs_root(path)
  if is_windows then
    return path:match '^%a:$'
  else
    return path == '/'
  end
end

-- Returns if the specified path is an absolute path.
--- @path path string
--- @return boolean
function M.is_absolute(path)
  if is_windows then
    return path:match '^%a:' or path:match '^\\\\'
  else
    return path:match '^/'
  end
end

-- Returns the directory name of the specified path.
--- @param path string
--- @return string?
function M.dirname(path)
  local strip_dir_pat = '/([^/]+)$'
  local strip_sep_pat = '/$'
  if not path or #path == 0 then
    return
  end
  local result = path:gsub(strip_sep_pat, ''):gsub(strip_dir_pat, '')
  if #result == 0 then
    if is_windows then
      return path:sub(1, 2):upper()
    else
      return '/'
    end
  end
  return result
end

-- Joins the specified file system paths.
function M.join(...)
  return table.concat(vim.iter({ ... }):flatten():totable(), '/')
end

-- Traverses the parent directories starting at the specified path until
-- the file system root. Calls the specified callback function at each
-- parent directory.
--- @param path string
--- @param cb function
function M.traverse_parents(path, cb)
  path = uv.fs_realpath(path)
  local dir = path

  -- Just in case our algo is buggy, don't infinite loop.
  for _ = 1, 100 do
    dir = M.dirname(dir)
    if not dir then
      return
    end

    -- If we can't ascend further, then stop looking.
    if cb(dir, path) then
      return dir, path
    end
    if M.is_fs_root(dir) then
      break
    end
  end
end

-- Traverses the parent directories starting at the specified path until
-- the file system root.
--- @param path string
function M.iterate_parents(path)
  local function it(_, v)
    if v and not M.is_fs_root(v) then
      v = M.dirname(v)
    else
      return
    end
    if v and uv.fs_realpath(v) then
      return v, path
    else
      return
    end
  end
  return it, path, path
end

-- Returns if the speciifed path is a descendant directory of the
-- specified root path.
--- @param root string
--- @param path string
--- @return boolean
function M.is_descendant(root, path)
  if not path then
    return false
  end

  local function cb(dir, _)
    return dir == root
  end

  local dir, _ = M.traverse_parents(path, cb)

  return dir == root
end

return M
