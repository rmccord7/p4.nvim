if vim.b.did_ftplugin then
  return
end

vim.b.did_ftplugin = true

vim.bo.autoindent = true
vim.bo.smartindent = true
