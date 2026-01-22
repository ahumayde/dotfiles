-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]
vim.cmd [[let g:fsharp#fsi_keymap = "custom"]]
vim.cmd [[let g:fsharp#fsi_keymap_send   = "<S-CR>"]]
vim.cmd [[let g:fsharp#fsi_keymap_toggle = "<C-CR>"]]
vim.cmd [[let g:fsharp#unused_declarations_analyzer = 1]]
vim.cmd [[let g:neo_tree_remove_legacy_commands = 1]]
-- vim.lsp.codelens = false
-- vim.lsp.codelens.on_codelens = function(e, r, c) return nil end

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- TELESCOPE
    use {
        'nvim-telescope/telescope.nvim',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    -- COLOUR SCHEMES
    use({ 'folke/tokyonight.nvim', as = 'tokyonight', })
    use({ 'Mofiqul/vscode.nvim', as = 'vscode', })
    use({ 'rose-pine/neovim', as = 'rose-pine', })
    use({ "catppuccin/nvim", as = "catppuccin" })
    use({ "bluz71/vim-nightfly-colors", as = "nightfly" })
    use({ "joshdick/onedark.vim", as = "onedark" })
    use({ "EdenEast/nightfox.nvim", as = "nightfox" })
    use({ "olivercederborg/poimandres.nvim", as = "poimandres" })

    -- OTHERS
    use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
    use('nvim-treesitter/playground')
    use("nvim-lua/plenary.nvim")
    use('nvim-treesitter/nvim-treesitter-context')
    use('theprimeagen/harpoon')
    use('mbbill/undotree')
    use('tpope/vim-fugitive')
    use('andweeb/presence.nvim')

    -- LSP
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },

        }
    }

    -- FSharp F#
    -- use { 'autozimu/LanguageClient-neovim', branch = 'next', run = 'bash install.sh' }
    use { "ionide/Ionide-vim", }

    -- VERILOG
    use { 'vhda/verilog_systemverilog.vim', as = 'verilog' }

    -- FILE TREE
    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v2.x",
        requires = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
        }
    }
    -- use {
    --     'nvim-tree/nvim-tree.lua',
    --     requires = {
    --         'nvim-tree/nvim-web-devicons',
    --     },
    --     config = function()
    --         require("nvim-tree").setup {}
    --     end
    -- }
    -- use("nvim-tree/nvim-web-devicons")

    -- FLUTTER
    use {
        'akinsho/flutter-tools.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
            'stevearc/dressing.nvim', -- optional for vim.ui.select
        },
    }

    -- VIM BE GOOD
    use { 'ThePrimeagen/vim-be-good' }

    -- COMMENT
    use {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
    }

    -- MULTI LINE
    use {
        'mg979/vim-visual-multi',
        branch = 'master',
    }

    -- MARKDOWN
    use{
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
    }

    --[[ use({ "iamcco/markdown-preview.nvim",
          run = "cd app && npm install",
          ft = { "markdown" },
          setup = function()
             vim.g.mkdp_filetypes = { "markdown" } 
          end, 
    }) ]]

end)
