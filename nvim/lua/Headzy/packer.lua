-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]
vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

return require('packer').startup(function(use)

-- Packer can manage itself
	use 'wbthomason/packer.nvim'

-- TELESCOPE
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.1',
		-- or                            , branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

-- COLOUR SCHEMES
	use({
	    'folke/tokyonight.nvim',
	    as = 'tokyonight',
	})

	use({
	    'Mofiqul/vscode.nvim',
	    as = 'vscode',
	})

	use({
	    'rose-pine/neovim',
	    as = 'rose-pine',
	})

-- OTHERS
	use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'} )
	use('nvim-treesitter/playground')
    use("nvim-lua/plenary.nvim")
	use('theprimeagen/harpoon')
	use('mbbill/undotree')
	use('tpope/vim-fugitive')
	use("nvim-treesitter/nvim-treesitter-context");

-- LSP
	use {
	  'VonHeikemen/lsp-zero.nvim',
	  branch = 'v1.x',
	  requires = {
		  -- LSP Support
		  {'neovim/nvim-lspconfig'},
		  {'williamboman/mason.nvim'},
		  {'williamboman/mason-lspconfig.nvim'},

		  -- Autocompletion
		  {'hrsh7th/nvim-cmp'},
		  {'hrsh7th/cmp-buffer'},
		  {'hrsh7th/cmp-path'},
		  {'saadparwaiz1/cmp_luasnip'},
		  {'hrsh7th/cmp-nvim-lsp'},
		  {'hrsh7th/cmp-nvim-lua'},

		  -- Snippets
		  {'L3MON4D3/LuaSnip'},
		  {'rafamadriz/friendly-snippets'},
	  }
    }
    use {
        'vhda/verilog_systemverilog.vim',
        as = 'verilog'
    }
-- File Tree

    -- use {
    --     'nvim-tree/nvim-tree.lua',
    --     requires = {
    --         'nvim-tree/nvim-web-devicons',
    --     },
    --     config = function()
    --         require("nvim-tree").setup {}
    --     end
    -- }

    use("nvim-tree/nvim-web-devicons")
    use {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v2.x",
        requires = {
          "nvim-lua/plenary.nvim",
          "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
          "MunifTanjim/nui.nvim",
        }
      }

-- FLUTTER
    use {
        'akinsho/flutter-tools.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
            'stevearc/dressing.nvim', -- optional for vim.ui.select
        },
    }

-- VIM BE GOOD
    use {
        'ThePrimeagen/vim-be-good'
    }
end)


