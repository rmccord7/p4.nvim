local p4_notify = require("p4.notify")

local tp4_actions = require("telescope._extensions.p4.actions")

local M = {}

--- Diffs the P4 change list's files against the head revision.
---
--- @param prompt_bufnr integer Prompt buffer number.
---
function M.diff_files(prompt_bufnr)
  local selection = tp4_actions.get_selection(prompt_bufnr)

  if selection then

    -- TODO: Implement
    p4_notify("Not supported", vim.log.level.ERROR);
  end
end

--- Reverts the P4 change list's files.
---
--- @param prompt_bufnr integer Prompt buffer number.
---
function M.revert_files(prompt_bufnr)

  local selection = tp4_actions.get_selection(prompt_bufnr)

  if selection then

    -- TODO: Implement
    p4_notify("Not supported", vim.log.level.ERROR);
  end
end

--- Shelves the P4 change list's files.
---
--- @param prompt_bufnr integer Prompt buffer number.
---
function M.shelve_files(prompt_bufnr)

  local selection = tp4_actions.get_selection(prompt_bufnr)

  if selection then

    -- TODO: Implement
    p4_notify("Not supported", vim.log.level.ERROR);
  end
end

--- Un-shelves the P4 change list's files.
---
--- @param prompt_bufnr integer Prompt buffer number.
---
function M.unshelve_files(prompt_bufnr)
  local selection = tp4_actions.get_selection(prompt_bufnr)

  if selection then

    -- TODO: Implement
    p4_notify("Not supported", vim.log.level.ERROR);
  end
end

return M
