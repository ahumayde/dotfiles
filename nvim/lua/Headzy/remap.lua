vim.g.mapleader = " "

-- Previous
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- NEW LINE
vim.keymap.set("n", "<CR>", "o<Esc>")
vim.keymap.set("n", "<BS>", "O<Esc>")

-- SHIFT UP
vim.keymap.set("n", "<A-k>", ":m-2<CR>")
vim.keymap.set("v", "<A-k>", ":m-2<CR>gv")
vim.keymap.set("x", "<A-k>", ":m-2<CR>gv")

-- SHIFT DOWN
vim.keymap.set("n", "<A-j>", ":m+<CR>")
vim.keymap.set("v", "<A-j>", ":m'>+<CR>gv")
vim.keymap.set("x", "<A-j>", ":m'>+<CR>gv")

-- ESCAPE TERMINAL
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

-- SHIFT TAB
vim.keymap.set("i", "<S-Tab>", "<C-d>")
vim.keymap.set("n", "<S-Tab>", "<<")
vim.keymap.set("x", "<S-Tab>", "<")

-- TAB
vim.keymap.set("n", "<Tab>", ">>")
vim.keymap.set("x", "<Tab>", ">")
