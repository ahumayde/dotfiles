-- lua/config/options.lua
-- Plain vim.opt settings. No plugin dependencies allowed in this file —
-- if a setting only makes sense because of a plugin, it belongs in that
-- plugin's spec under lua/plugins/ instead.

local opt = vim.opt

-- Leader (must be set before plugins load in init.lua)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

opt.guicursor = "i-ci-ve-c:ver25,r-cr:hor20"

-- UI
vim.g.have_nerd_font = true
opt.guicursor = "i-ci-ve-c:ver25,r-cr:hor20"
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Indentation
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.autoindent = true
opt.smartindent = true
opt.expandtab = true
opt.breakindent = true
opt.wrap = false
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = "indent"

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Files / persistence
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo"

-- Behaviour
vim.schedule(function() vim.o.clipboard = "unnamedplus" end) -- opt.clipboard = "unnamedplus"
vim.o.showmode = false
vim.o.shell = "pwsh"
opt.mouse = "a"
opt.confirm = true
opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = { "menuone", "noselect" }
