vim.g.mapleader = " "

-- CHANGE BUFFER
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>h", ":help ")
vim.keymap.set("n", "<leader>t", "<C-w>s:term<CR>")

vim.keymap.set("n", "<leader>n", "<C-w>")

-- TERMINAL
vim.keymap.set("t", "<leader><Esc>", "<C-\\><C-n><C-w>q")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
vim.keymap.set("t", "<Tab>", "<C-\\><C-n>")

-- SELECTION 
vim.keymap.set("n", "<C-a>", "GVgg")
vim.keymap.set("n", "<leader>s", "GVgg:s/")
vim.keymap.set("x", "<leader>s", ":s/")
vim.keymap.set("v", "<leader>s", ":s/")

-- NEW LINE
vim.keymap.set("n", "<CR>", "o<Esc>")
vim.keymap.set("n", "<BS>", "O<Esc>")

-- SHIFT UP
vim.keymap.set("n", "<A-k>", ":m-2<CR>")
vim.keymap.set("v", "<A-k>", ":m-2<CR>gv=gv")
vim.keymap.set("x", "<A-k>", ":m-2<CR>gv=gv")
vim.keymap.set("v", "K", ":m-2<CR>gv=gv")
vim.keymap.set("x", "K", ":m-2<CR>gv=gv")

-- SHIFT DOWN
vim.keymap.set("n", "<A-j>", ":m+<CR>")
vim.keymap.set("v", "<A-j>", ":m'>+<CR>gv=gv")
vim.keymap.set("x", "<A-j>", ":m'>+<CR>gv=gv")
vim.keymap.set("v", "J", ":m'>+<CR>gv=gv")
vim.keymap.set("x", "J", ":m'>+<CR>gv=gv")

-- TAB
vim.keymap.set("n", "<Tab>", ">>")
vim.keymap.set("x", "<Tab>", ">")

-- SHIFT TAB
vim.keymap.set("i", "<S-Tab>", "<C-d>")
vim.keymap.set("n", "<S-Tab>", "<<")
vim.keymap.set("x", "<S-Tab>", "<")

-- SCROLLING
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- SEARCHING
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "*", "*zzzv")
vim.keymap.set("n", "*", "*zzzv")
vim.keymap.set("n", "#", "#zzzv")

-- LSP
-- "gd"  -> go to definition
-- "K"   -> hover
-- "vf"  -> format
-- "vrn" -> rename
-- "vca" -> code action
-- "vdi" -> diagnostic info
-- "vdo" -> diagnostic open 
-- "vdc" -> diagnostic close
-- "[d"  -> diagnostic prev
-- "]d"  -> diagnostic next
