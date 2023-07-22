vim.g.mapleader = " "

-- Previous
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- NEW LINE
vim.keymap.set("n", "<CR>", "o<Esc>")
vim.keymap.set("n", "<BS>", "O<Esc>")

-- SHIFT UP
vim.keymap.set("n", "<A-k>", ":m-2<CR>")
vim.keymap.set("v", "<A-k>", ":m-2<CR>gv=gv")
vim.keymap.set("x", "<A-k>", ":m-2<CR>gv=gv")

-- SHIFT DOWN
vim.keymap.set("n", "<A-j>", ":m+<CR>")
vim.keymap.set("v", "<A-j>", ":m'>+<CR>gv=gv")
vim.keymap.set("x", "<A-j>", ":m'>+<CR>gv=gv")

-- ESCAPE TERMINAL
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- SHIFT TAB
vim.keymap.set("i", "<S-Tab>", "<C-d>")
vim.keymap.set("n", "<S-Tab>", "<<")
vim.keymap.set("x", "<S-Tab>", "<")

-- TAB
vim.keymap.set("n", "<Tab>", ">>")
vim.keymap.set("x", "<Tab>", ">")

-- SCROLLING
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "*", "*zzzv")
vim.keymap.set("n", "#", "#zzzv")

