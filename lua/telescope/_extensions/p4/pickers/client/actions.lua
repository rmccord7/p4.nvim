local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

local p4_notify = require("p4.notify")

local p4_cl = require("p4.api.cl")

local p4_log = require("p4.core.log")
local p4_selected_client = require("p4.core.selected_client")

local tp4_util = require("telescope._extensions.p4.pickers.util")

--- Action to set the client's CL as the current selected CL.
---
--- @param cl_num integer Identifies the telescope prompt buffer.
local function open_cl_files_picker(cl_num)

  local cl = p4_cl.new(cl_num)

  -- Get the list of files from the CL spec
  cl:get_files_from_spec(result.stdout)

  if not vim.tbl_isempty then
    require("telescope._extensions.p4.pickers.cl").files_picker(cl)
  else
    p4_log.warn("CL doesn't contain any files")
  end
end

local M = {}

--- Action to set the client's CL as the current selected CL.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.update_selected_cl(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then

    p4_selected_client.set_current_cl(entry.name)

    open_cl_files_picker(entry.name)
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to set the client's CL as the current selected CL.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.update_and_display_selected_cl_files(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then

    p4_selected_client.set_current_cl(entry.name)

  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to open the file list picker for files that are part of
--- the client's cl.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.display_cl_files(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    open_cl_files_picker(entry.name)
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to open the shelved file list picker for files that are part of
--- the client's cl.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.display_shelved_cl_files(prompt_bufnr)

  -- TODO: Need CL API support to display shelved files

  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement displaying shelved files

    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to delete the client's cl.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.delete_cl(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement deleting the CL

    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to revert the client's cl.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.revert_cl(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement reverting the CL

    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to shelve the client's cl.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.shelve_cl(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement shelving the CLs files

    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

--- Action to un-shelve the client's cl.
---
--- @param prompt_bufnr integer Identifies the telescope prompt buffer.
function M.unshelve_cl(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = actions_state.get_selected_entry()

  if entry then
    -- TODO: Implement un-shelving the CLs files
    p4_notify("Not supported", vim.log.level.ERROR);
  else
    tp4_util.warn_no_selection_action()
  end
end

return M
