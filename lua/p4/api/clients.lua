local log = require("p4.log")

local shell = require("p4.core.shell")

local client_cmds = require("p4.core.commands.client")
local cl_cmds = require("p4.core.commands.cl")

local client_api = require("p4.api.client")

--- @class P4_Clients
--- @field selected_client P4_Client? Selected P4 client
--- @field selected_client_cl integer Selected P4 client CL
--- @field list P4_Client[] List of P4 clients
local context = {
  client_list = {},
}

local api = {}

--- Adds a P4 client
---
--- @param client string P4 client
local function add_client(client)
  log.fmt_info("Add client: %s", client)
  table.insert(context.client_list, client)
end

--- Finds a P4 client
---
--- @param client? string P4 client
local function find_client(client)
  for _, c in ipairs(context.client_list) do
    if c.name == client then
      log.fmt_info("Found client: %s", client)
      return c
    end
  end
  return nil
end

--- Removes a P4 client
---
--- @param client string P4 client
local function remove_client(client)
  for k,v in ipairs(context.client_list) do
    if v.name == client then
      table.remove(context.client_list, k)
    end
  end
end

--- Sets the selected P4 client.
---
--- @param client string P4 client name
function api.set_client(client)

  log.info("Set client")

  if not find_client(client) then
    add_client(client)
  end

  -- Determine the workspace root.
  local root = ''
  local spec = nil

  local result = shell.run(client_cmds.read_spec(client))

  if result.code == 0 then

    spec = result.stdout

    for _, line in ipairs(vim.split(spec, "\n")) do
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

    context.selected_client = client_api.new(nil, client, spec)

    if context.selected_client then
      log.fmt_info("Client: %s", context.selected_client.name);
      log.fmt_info("Client root: %s", context.selected_client.spec.root)
    end

  else
    log.error("Could not find client workspace root")
  end

  if not context.selected_client then
    log.error("Set client failed")
  end
end

--- Gets the selected P4 client.
---
--- @return string? client P4 client name
function api.get_client()
  local client = nil
  if context.selected_client then
    client = context.selected_client.name
  else
    log.error("Client not set")
  end

  if not client then
    log.error("Get client failed")
  end

  return client
end

--- Sets the selected P4 client's CL.
---
--- @param cl integer P4 change list number
function api.set_client_cl(cl)

  log.info("Set client CL")

  -- api.ke sure client has been set previously.
  local client = find_client()

  if context.selected_client then

    -- No need to proceed if the CL is already set.
    if not context.selected_client_cl or context.selected_client_cl ~= cl  then

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

              context.selected_client_cl = cl

              log.fmt_info("Client: %s", context.selected_client.name);
              log.fmt_info("Client CL: %u", context.selected_client_cl);

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

--- Gets the selected P4 client's selected CL.
---
--- @return integer?  P4 client's CL
function api.get_client_cl()
  local cl = nil
  if context.selected_client then
    if context.selected_client_cl then
      cl = context.selected_client_cl
    else
      log.error("Client's CL not set")
    end
  else
    log.error("Client not set")
  end

  if not cl then
    log.error("Get client cl failed")
  end

  return cl
end

--- Cleans up the selected client if a P4 client is not set.
---
--- @param client string P4 client name
function api.cleanup_client(client)

  if context.selected_client and context.selected_client.name == client then
    context.selected_client = nil
    context.selected_client_cl = nil
  end

  remove_client(client)
end

return api
