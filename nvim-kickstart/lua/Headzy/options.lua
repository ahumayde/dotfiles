-- [[ Setting options ]]
-- (`:help vim.o`, `:help vim.opt`)
-- `:help lua-options-guide` `:help lua-options`, `:help option-list`

-- Set <SPACE> Leader Key (`:help mapleader`)
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI (NerdFont & Cursor)
-- TODO: Check if vim.opt accepts list args
-- vim.opt.guicursor = { "i-ci-ve-c:ver25", "r-cr:hor20" }
vim.g.have_nerd_font = true
vim.opt.guicursor = "i-ci-ve-c:ver25,r-cr:hor20"

-- Enable mouse mode
vim.o.mouse = "a"

-- Don't show the mode (already in the status line)
vim.o.showmode = false

-- Sync clipboard between OS and Neovim. (`:help 'clipboard'`)
-- Schedule the setting after `UiEnter` because it can increase startup-time.
-- TODO: look into `unnamed` clipboard as well
-- vim.opt.clipboard = "unnamed,unnamedplus"
vim.schedule(function() vim.o.clipboard = "unnamedplus" end)

-- Show line numbers (Current & Relative)
vim.opt.number = true
vim.opt.relativenumber = true

-- Indent & Tab Spacing (four spaces)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Automatic Indenting
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Enable Folding (Indent)
vim.opt.foldlevelstart = 99
vim.opt.foldmethod = "indent"

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching (EXCEPT if `\C` || [A-Z] is in the search term)
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update & mapped sequence wait time (ms)
-- TODO: compare with original/personal setting
-- vim.opt.updatetime = 50
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = false
vim.opt.splitbelow = false

-- Displays whitespace character lists (`:help 'list'`, `:help 'listchars'`)
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type! (sed)
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
-- TODO: compare with original/personal setting
-- vim.opt.scrolloff = 4
vim.opt.scrolloff = 10

-- Raise unsaved changes confirmation dialog (`:help 'confirm'`)
vim.opt.confirm = true

-- Prevents long lines of text from wrapping
vim.opt.wrap = false
vim.opt.breakindent = true

-- TODO: Look into swap files more (esp on linux/android)
-- vim.opt.swapfile = false

-- Highlights & Jumps to search patterns
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Enables 24-bit RGB in TUI
vim.opt.termguicolors = true

-- TODO: Figure out wtf this does
-- vim.opt.isfname:append("@-@")

-- FIXME: Check if this works/fix it
-- vim.g.neotree_show_hidden = 1

-- Windows
-- vim.o.shell = "bash"
-- vim.g.python3_host_prog = "C:\\Users\\AHumayde\\AppData\\Local\\Microsoft\\WindowsApps\\python3.12.exe"
