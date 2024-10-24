local log = require("p4.log")
local notify = require("p4.notify")

local env = require("p4.core.env")
local shell = require("p4.core.shell")

local client_cmds = require("p4.core.commands.client")
local cl_cmds = require("p4.core.commands.cl")

--- @class P4_Clients
--- @field selected_client P4_Client Selected P4 client
--- @field selected_client_cl integer Selected P4 client CL
--- @field list P4_Client[] List of P4 clients
local M = {
  client_list = {},
}

--- Adds a P4 client
---
--- @param client string P4 client
local function add_client(client)
  table.insert(M.client_list, client)
end

--- Finds a P4 client
---
--- @param client? string P4 client
local function find_client(client)
  for _, c in ipairs(t) do
    if c.name == client then
      return c
    end
  end
  return nil
end

--- Removes a P4 client
---
--- @param client string P4 client
local function remove_client(client)
  for k,v in ipairs(M.client_list) do
    if v.name == client then
      table.remove(M.client_list, k)
    end
  end
end

--- Updates the selected P4 client.
---
--- @param client string P4 client name
function M.set_client(client)

  client = client or env.client

  if not find_client(client) then
    add_client(client)
  end

  -- Determine the workspace root.
  local root = ''

  local result = shell.run(client_cmds.read_spec(client))

  if result.code == 0 then

    for _, line in ipairs(vim.split(result.stdout, "\n")) do
      if line:find("^Root") then

        chunks = {}
        for substring in line:gmatch("%S+") do
          table.insert(chunks, substring)
        end

        -- TODO: Handle alt root?

        root = chunks[2]
        break
      end
    end
  end

  -- Update the selected client.
  if string.len(root) then

    M.selected_client:new(nil, nil, nil)

    notify("Updated selected client", vim.log.levels.INFO);
    log.fmt_info("Updated selected client, %s, %s", client, root)

  else
    log.error("Could not find client workspace root")
  end
end

--- Updates the selected P4 client's CL.
---
--- @param cl integer P4 change list number
function M.set_client_cl(cl)

  -- Make sure client has been set previously.
  local client = find_client()

  if M.selected_client then

    -- No need to proceed if the CL is already set.
    if not M.selected_client_cl or M.selected_client_cl ~= cl  then

      -- Read the CL spec to ensure it is valid for this client.
      local result = shell.run(cl_cmds.read_spec(cl))

      if result.code == 0 then

        for _, line in ipairs(vim.split(result.stdout, "\n")) do
          if line:find("^Client") then

            chunks = {}
            for substring in line:gmatch("%S+") do
              table.insert(chunks, substring)
            end

            if chunks[2] == client then

              M.selected_client_cl = cl

            else
              log.error("CL does not belong to the current selected client")
            end
            break
          end
        end
      end
    end
  else
    log.error("Client not set")
  end
end

--- Cleans up the selected client if a P4 client is not set.
---
--- @param client string P4 client name
function M.cleanup_client(client)

  if M.selected_client and M.selected_client.name == client then
    M.selected_client = nil
    M.selected_client_cl = nil
  end

  remove_client(client)
end

return M
