local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")

M = {}

  --- Action to get the current selection.
  ---
  --- @param prompt_bufnr integer Prompt buffer number.
  ---
function M.get_selection(prompt_bufnr)
  local selection = {}

  local picker = actions_state.get_current_picker(prompt_bufnr)

  if #picker:get_multi_selection() > 0 then
    for _, item in ipairs(picker:get_multi_selection()) do
      table.insert(selection, item[1])
    end
  else
    table.insert(selection, actions_state.get_selected_entry()[1])
  end

  print(vim.inspect(selection))

  return(selection)
end

return M
