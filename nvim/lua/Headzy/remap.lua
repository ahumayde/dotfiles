vim.g.mapleader = " "
-- vim.api.nvim_del_keymap("t","<Tab>")

-- SAVING
vim.keymap.set("n", "<A-w>", vim.cmd.w)
vim.keymap.set("n", "<A-q>", vim.cmd.q)
vim.keymap.set("n", "<leader>w", vim.cmd.w)
vim.keymap.set("n", "<leader>quit", vim.cmd.qa)

-- CHANGE BUFFER
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>h", ":help ")
vim.keymap.set("n", "<leader>b", "<C-6>")
vim.keymap.set("n", "<leader>n", "<C-w>")
vim.keymap.set("n", "<C-b>", "<C-6>")

-- TERMINAL
vim.keymap.set("n", "<leader>nt", "<C-w>s:term<CR><C-w>9-i")
vim.keymap.set("n", "<leader>t", "<C-w>s:term<CR><C-w>9-i")
vim.keymap.set("n", "<leader>ts", "<C-w>s:term<CR><C-w>9-i")
vim.keymap.set("n", "<leader>tk", "<C-w>s:term<CR><C-w>9-i")
vim.keymap.set("n", "<leader>tj", "<C-w>s<C-w>j:term<CR><C-w>8-i")
vim.keymap.set("n", "<leader>tv", "<C-w>v<C-w>l:term<CR>i")
vim.keymap.set("n", "<leader>tl", "<C-w>v<C-w>l:term<CR>i")
vim.keymap.set("n", "<leader>th", "<C-w>v:term<CR>i")
vim.keymap.set("t", "<S-Esc>", "<C-\\><C-n><C-w>q")
vim.keymap.set("t", "<S-Tab>", "<C-\\><C-n><C-w>q")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
-- vim.keymap.set("t", "<Tab>", "<C-\\><C-n>")

-- SELECTION
vim.keymap.set("n", "<C-x>", "<C-v>")
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
vim.keymap.set("n", "#", "#zzzv")

-- LSP
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>vdi", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_next)
vim.keymap.set("n", "]d", vim.diagnostic.goto_prev)
vim.keymap.set({ "n", "x" }, "<leader>vdc", ":lua vim.diagnostic.config({virtual_text = false})<CR>")
vim.keymap.set({ "n", "x" }, "<leader>vdo", ":lua vim.diagnostic.config({virtual_text = true})<CR>")
vim.keymap.set({ "n", "x" }, "<leader>vf", ":lua vim.lsp.buf.format({async = false, timeout_ms = 10000})<CR>")

-- Not Using
vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references)
vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol)
vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help)

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
