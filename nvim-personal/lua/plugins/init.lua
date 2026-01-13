return { 
    { 
      "nvim-lua/plenary.nvim", 
      name = "plenary" 
    },

    -- UndoTree
    { "mbbill/undotree",
      config = function()
          vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
      end
    },

    -- Flutter Tools
    {
        "akinsho/flutter-tools.nvim",
        dependencies = {
            "plenary",
            "stevearc/dressing.nvim", -- optional for vim.ui.select
        },
    },

    -- Vim Be Good
    { "ThePrimeagen/vim-be-good" },

    -- Markdown Preview
    {
        "iamcco/markdown-preview.nvim",
        run = function() vim.fn["mkdp#util#install"]() end,
        ft = { "markdown" },
        setup = function()
           vim.g.mkdp_filetypes = { "markdown" } 
        end, 
    },

    -- MULTI LINE
    -- { "mg979/vim-visual-multi", branch = "master" },

    -- Fugitive
    -- { "tpope/vim-fugitive" },
    
    -- VERILOG
    -- { "vhda/verilog_systemverilog.vim", as = "verilog" },

    -- FSharp F#
    -- { "autozimu/LanguageClient-neovim", branch = "next", run = "bash install.sh" }
    -- { "ionide/Ionide-vim", }
    
    -- { "iamcco/markdown-preview.nvim",
    --      run = "cd app && npm install",
    -- }
}
