local plenary_dir = vim.uv.os_getenv("PLENARY_NVIM_DIR") or "../plenary.nvim/"

vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append(plenary_dir)

vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/load_present.lua")
