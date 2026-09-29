-- lua/config/keymaps.lua

local keymap = vim.tbl_extend('force', {}, vim.keymap)
keymap.set = function(mode, lhs, rhs, desc, opts)
  opts = vim.tbl_extend('force', {
    silent = true,
    noremap = true,
    desc = desc,
  }, opts or {})

  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Usage:
keymap.set('n', '<leader>w', '<cmd>write<cr>', 'Save file')
keymap.set('v', 'J', ":m '>+1<cr>gv=gv", 'Move line down')
keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', 'Delete buffer', { nowait = true })

-- ============================================================================
-- File Operations & Quitting
-- ============================================================================
keymap.set("n", "<leader>w", "<cmd>write<cr>", "Save current file")
keymap.set("n", "<A-w>", "<cmd>write<cr>", "Save current file")
keymap.set("n", "<A-q>", "<cmd>quit<cr>", "Quit current window")
keymap.set("n", "<leader>quit", "<cmd>qa!<cr>", "Quit all (force)")

-- ============================================================================
-- Window Navigation & Resizing
-- ============================================================================
-- Focus movement
keymap.set("n", "<C-h>", "<C-w>h", "Move to left window")
keymap.set("n", "<C-j>", "<C-w>j", "Move to lower window")
keymap.set("n", "<C-k>", "<C-w>k", "Move to upper window")
keymap.set("n", "<C-l>", "<C-w>l", "Move to right window")
keymap.set("n", "<leader>n", "<C-w>", "Window command prefix")
keymap.set("n", "<leader>nw", "<C-w>w", "Cycle to next window")
keymap.set("n", "<leader>nW", "<C-w>W", "Cycle to previous window")

-- Window resizing
keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", "Increase window height")
keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", "Decrease window height")
keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", "Decrease window width")
keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", "Increase window width")
keymap.set("n", "<leader>r1", "<cmd>resize 5<cr>", "Set window height to 5")
keymap.set("n", "<leader>r2", "<cmd>resize 10<cr>", "Set window height to 10")
keymap.set("n", "<leader>r3", "<cmd>resize 15<cr>", "Set window height to 15")

-- ============================================================================
-- Buffer Management
-- ============================================================================
keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", "Previous buffer")
keymap.set("n", "<S-l>", "<cmd>bnext<cr>", "Next buffer")
keymap.set("n", "<leader>b", "<cmd>buffer #<cr>", "Switch to alternate buffer")
keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")

-- ============================================================================
-- Navigation, Scrolling & View Centring
-- ============================================================================
-- Start / end of line jumps
keymap.set("n", "H", "^", "Jump to first non-blank character")
keymap.set("n", "L", "$", "Jump to end of line")

-- Jump history
keymap.set("n", "<A-f>", "<C-i>", "Jump forward in jumplist")
keymap.set("n", "<A-b>", "<C-o>", "Jump backward in jumplist")

-- Marks
keymap.set("n", "<leader>g", "`", "Jump to mark")

-- Centred scrolling & searching
keymap.set("n", "<C-d>", "<C-d>zz", "Scroll down (centred)")
keymap.set("n", "<C-u>", "<C-u>zz", "Scroll up (centred)")
keymap.set("n", "<S-m>", "zz", "Centre cursor on screen")
keymap.set("n", "n", "nzzzv", "Next search result (centred)")
keymap.set("n", "N", "Nzzzv", "Previous search result (centred)")
keymap.set("n", "*", "*zzzv", "Search word forward (centred)")
keymap.set("n", "#", "#zzzv", "Search word backward (centred)")

-- Keep cursor stationary while joining lines
keymap.set("n", "J", "mzJ`z", "Join lines keeping cursor position")

-- Clear highlights
keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlights")

-- ============================================================================
-- Editing, Movement & Selection
-- ============================================================================
-- Block visual mode & select all
keymap.set("n", "<C-x>", "<C-v>", "Visual block mode")
keymap.set("n", "<C-a>", "ggVG", "Select entire buffer")

-- Indentation (keeps visual selection active)
keymap.set("n", "<Tab>", ">>", "Indent line")
keymap.set("n", "<S-Tab>", "<<", "Unindent line")
keymap.set("x", "<Tab>", ">gv", "Indent selection")
keymap.set("x", "<S-Tab>", "<gv", "Unindent selection")

-- Move lines up and down
keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", "Move line down")
keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", "Move line up")
keymap.set("v", "J", ":m '>+1<cr>gv=gv", "Move selection down", { silent = false })
keymap.set("v", "K", ":m '<-2<cr>gv=gv", "Move selection up", { silent = false })
keymap.set("x", "<A-j>", ":m '>+1<cr>gv=gv", "Move selection down", { silent = false })
keymap.set("x", "<A-k>", ":m '<-2<cr>gv=gv", "Move selection up", { silent = false })

-- Insert blank lines without entering insert mode
keymap.set("n", "]<Space>", "m`o<Esc>``", "Add blank line below")
keymap.set("n", "[<Space>", "m`O<Esc>``", "Add blank line above")

-- In-place substitutions
keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], "Substitute word under cursor", { silent = false })
keymap.set("x", "<leader>s", ":s/", "Substitute in selection", { silent = false })

-- Fast insert-mode escapes
-- FIX: 
keymap.set("i", "<Esc>" , "<Esc>l", "Delete previous word")
keymap.set("i", "<C-Del>", "<C-W>", "Delete next word")
keymap.set("i", "<C-BS>" , "<Esc>ldb", "Delete previous word")
keymap.set("i", "<A-i>"  , "<Esc>", "Exit insert mode")
keymap.set("i", "<S-Tab>", "<Esc>", "Exit insert mode")

-- ============================================================================
-- Terminal Management
-- ============================================================================
-- Terminal escapes
keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")
keymap.set("t", "<A-i>", "<C-\\><C-n>", "Exit terminal mode")
keymap.set("t", "<S-Esc>", "<C-\\><C-n><cmd>close<cr>", "Close terminal window")

-- Terminal spawns (Horizontal splits)
keymap.set("n", "<leader>t",  "<cmd>belowright 8split | terminal<cr>i", "Open bottom terminal")
keymap.set("n", "<leader>ts", "<cmd>belowright 8split | terminal<cr>i", "Open bottom terminal")
keymap.set("n", "<leader>tj", "<cmd>belowright 10split | terminal<cr>i", "Open bottom terminal (large)")

-- Terminal spawns (Vertical splits)
keymap.set("n", "<leader>tv", "<cmd>belowright vsplit | terminal<cr>i", "Open vertical terminal")
keymap.set("n", "<leader>tl", "<cmd>belowright vsplit | terminal<cr>i", "Open vertical terminal")

-- File explorer fallback
keymap.set("n", "<leader>pv", vim.cmd.Ex, "Open Netrw explorer")

-- ============================================================================
-- Diagnostics (Global)
-- ============================================================================
keymap.set("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
keymap.set("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
keymap.set("n", "<leader>vdi", vim.diagnostic.open_float, "Show diagnostic popup")
keymap.set("n", "<leader>q", vim.diagnostic.setloclist, "Add diagnostics to location list")
keymap.set("n", "<leader>vdc", function()
  vim.diagnostic.config({ virtual_text = false })
end, "Disable diagnostic virtual text")
keymap.set("n", "<leader>vdo", function()
  vim.diagnostic.config({ virtual_text = true })
end, "Enable diagnostic virtual text")

