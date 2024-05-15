local uv = vim.loop

local p4_config = require('p4.config')

local is_windows = uv.os_uname().version:match 'Windows'

local function login(password, opts)
    opts = opts or {}

    return {
        "p4",
        "login",
        password,
    }
end

local M = {}

function M.print(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "P4" })
end

function M.warn(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = "P4" })
end

function M.error(msg)
    vim.notify(msg, vim.log.levels.ERROR, { title = "P4" })
end

function M.debug(msg)
    if p4_config.opts.debug then
        vim.notify(msg, vim.log.levels.DEBUG, { title = "P4" })
    end
end

function M.run_command(cmd)
    if cmd then

      local result = vim.system(cmd,
      {
          text = true,
      }):wait()

      if result.code > 0 then
          M.error(result.stderr)

          -- If we failed because we are not logged in, then log in and re-run the command.
          if string.find(result.stderr, "Your session has expired, please login again.", 1, true) or
             string.find(result.stderr, "Perforce password (P4PASSWD) invalid or unset.", 1, true) then

              vim.fn.inputsave()
              local password = vim.fn.inputsecret("Password: ")
              vim.fn.inputrestore()

              result = vim.system(login(), { stdin = password }):wait()

              if result.code == 0 then
                  result = vim.system(cmd,
                  {
                      text = true,
                  }):wait()

                  if result.code > 0 then
                      M.error(result.stderr)
                  end
              else
                  M.error(result.stderr)
              end
          end
      end

      return result
    end
end

-- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L209
M.path = (function()
  local function escape_wildcards(path)
    return path:gsub('([%[%]%?%*])', '\\%1')
  end

  local function sanitize(path)
    if is_windows then
      path = path:sub(1, 1):upper() .. path:sub(2)
      path = path:gsub('\\', '/')
    end
    return path
  end

  local function exists(filename)
    local stat = uv.fs_stat(filename)
    return stat and stat.type or false
  end

  local function is_dir(filename)
    return exists(filename) == 'directory'
  end

  local function is_file(filename)
    return exists(filename) == 'file'
  end

  local function is_fs_root(path)
    if is_windows then
      return path:match '^%a:$'
    else
      return path == '/'
    end
  end

  local function is_absolute(filename)
    if is_windows then
      return filename:match '^%a:' or filename:match '^\\\\'
    else
      return filename:match '^/'
    end
  end

  --- @param path string
  --- @return string?
  local function dirname(path)
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

  local function path_join(...)
    return table.concat(vim.tbl_flatten { ... }, '/')
  end

  -- Traverse the path calling cb along the way.
  local function traverse_parents(path, cb)
    path = uv.fs_realpath(path)
    local dir = path
    -- Just in case our algo is buggy, don't infinite loop.
    for _ = 1, 100 do
      dir = dirname(dir)
      if not dir then
        return
      end
      -- If we can't ascend further, then stop looking.
      if cb(dir, path) then
        return dir, path
      end
      if is_fs_root(dir) then
        break
      end
    end
  end

  -- Iterate the path until we find the rootdir.
  local function iterate_parents(path)
    local function it(_, v)
      if v and not is_fs_root(v) then
        v = dirname(v)
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

  local function is_descendant(root, path)
    if not path then
      return false
    end

    local function cb(dir, _)
      return dir == root
    end

    local dir, _ = traverse_parents(path, cb)

    return dir == root
  end

  local path_separator = is_windows and ';' or ':'

  return {
    escape_wildcards = escape_wildcards,
    is_dir = is_dir,
    is_file = is_file,
    is_absolute = is_absolute,
    exists = exists,
    dirname = dirname,
    join = path_join,
    sanitize = sanitize,
    traverse_parents = traverse_parents,
    iterate_parents = iterate_parents,
    is_descendant = is_descendant,
    path_separator = path_separator,
  }
end)()

function M.search_ancestors(startpath, func)
  vim.validate { func = { func, 'f' } }
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in M.path.iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

function M.find_p4_ancestor(startpath)
  return M.search_ancestors(startpath, function(path)
    M.debug("Path" .. M.path.sanitize(M.path.join(path, p4_config.opts.p4.config)))
    if M.path.is_file(M.path.join(path, p4_config.opts.p4.config)) then
      return path
    end
  end)
end

return M
