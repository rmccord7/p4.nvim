vim.filetype.add(
  {
    pattern = {
      [".*"] = function(_, bufnr)
        local content = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''

        if vim.regex([[^# A Perforce Change Specification]]):match_str(content) ~= nil then
          return "p4_change_spec"
        end
      end,
    }
  }
)
