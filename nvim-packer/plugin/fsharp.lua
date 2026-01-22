local lsp = require("lsp-zero")
local lspconfig = require('lspconfig')

-- lspconfig.fsautocomplete.setup {
--     cmd = { '/home/headzy/.dotnet/tools/fsautocomplete'},
--     filetypes = { 'fsharp' },
--     root_dir = lspconfig.util.root_pattern("*.fsproj", ".git"),
--     -- root_dir = lspconfig.util.root_pattern("*.sln", "*.fsproj", ".git"),
-- }

lspconfig.fsautocomplete.setup {
    cmd = {'/home/headzy/.dotnet/tools/fsautocomplete', '--background-service-enabled' },
    filetypes = { 'fsharp', '*.fs', '*.fsx', '*.fsi' },
    -- pattern = { 'fsharp', '*.fs', '*.fsx', '*.fsi' },
    root_dir = lspconfig.util.root_pattern("*.sln", "*.fsproj", ".git"),
}

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = ".fs,.fsx,*.fsi",
  command = [[set filetype=fsharp]]
})

-- require('ionide').setup {
--   on_attach = lsp.on_attach,
--   capabilities = lsp.capabilities,
-- }
