vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append("../plenary.nvim/")

vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/load_present.lua")
