local lsp = require("lsp-zero")
local lspconfig = require("lspconfig")

lsp.preset("recommended")

lsp.ensure_installed({
    'tsserver',
    'eslint',
    'rust_analyzer',
})

-- Fix Undefined global 'vim'
lsp.nvim_workspace()

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),
    ['<A-j>'] = cmp.mapping.select_next_item(cmp_select),
    ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<A-k>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<A-y>'] = cmp.mapping.confirm({ select = true }),
    ["<A-f>"] = cmp.mapping.complete(),
    ["<C-f>"] = cmp.mapping.complete(),
    ["<C-Space>"] = cmp.mapping.complete(), -- Enter
})
-- cmp_mappings['<Tab>'] = nil
-- cmp_mappings['<S-Tab>'] = nil

lsp.setup_nvim_cmp({
    mapping = cmp_mappings
})

lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn  = 'W',
        hint  = 'H',
        info  = 'I'
    }
})

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }
    -- lsp.default_keymaps({ buffer = bufnr })

    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vdi", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)

    -- Not Using
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end)

vim.keymap.set({ "n", "x" }, "<leader>vdc", ":lua vim.diagnostic.config({virtual_text = false})<CR>")
vim.keymap.set({ "n", "x" }, "<leader>vdo", ":lua vim.diagnostic.config({virtual_text = true})<CR>")
vim.keymap.set({ "n", "x" }, "<leader>vf", ":lua vim.lsp.buf.format({async = false, timeout_ms = 10000})<CR>")


lsp.setup()

vim.diagnostic.config({
    virtual_text = true
})

local warnings = {
    'E203',    -- Whitespace before colon
    'E221',    -- Multiple spaces before operator
    -- 'E223', -- Whitespace before operator
    -- 'E225', -- Missing whitespace around operator
    'E226', -- Missing whitespace around arithmetic operator
    'E231',    -- Missing whitespace after ','
    -- 'E301', -- Expected 1 blank line, found 0
    -- 'E302', -- Expected 2 blank lines, found 0
    -- 'E303', -- Too many blank lines (3)
    'E501',    -- Line too long (max-line-length)
    -- 'E503', -- Line break occurred before a binary operator
    -- 'W291', -- Trailing whitespace
    -- 'W293', -- Blank line contains whitespace
    -- 'F403', -- 'from module import *' used; unable to detect undefined names
    -- 'F405', -- 'foo.bar' may be undefined, or defined from star imports
}

lspconfig.pylsp.setup {
    settings = {
        pylsp = {
            plugins = {
                pyflakes = {
                    enabled = false,
                },
                flake8 = {
                    ignore = warnings,
                },
                pycodestyle = {
                    ignore = warnings,
                },
                pydocstyle = {
                    ignore = warnings,
                },
                pylint = {
                    ignore = warnings,
                },
            },
        },
    },
}
