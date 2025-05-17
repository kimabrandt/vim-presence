for name, url in pairs({
  plenary = "https://github.com/nvim-lua/plenary.nvim",
}) do
  local install_path = vim.fn.fnamemodify("/tmp/presence_test/" .. name, ":p")
  if vim.fn.isdirectory(install_path) == 0 then
    vim.fn.system({ "git", "clone", "--depth=1", url, install_path })
  end
  vim.opt.runtimepath:append(install_path)
  print(vim.opt.runtimepath)
end
