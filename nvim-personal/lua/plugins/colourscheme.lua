function ColourVim(color)
	color = color or "vscode"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" } )
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" } )
end

return {
    { "catppuccin/nvim", name = "catppuccin" },
    { "rose-pine/neovim", name = "rose-pine", },
    { "joshdick/onedark.vim", name = "onedark" },
    { "EdenEast/nightfox.nvim", name = "nightfox" },
    { "bluz71/vim-nightfly-colors", name = "nightfly" },
    { "olivercederborg/poimandres.nvim", name = "poimandres" },

    { 
        "Mofiqul/vscode.nvim", name = "vscode" , 
        config = function() 
            vim.cmd("colorscheme vscode")
            -- ColourVim()
        end
    },

    { 
        "folke/tokyonight.nvim", 
        name = "tokyonight", 
        config = function() 
          require("tokyonight").setup({
            styles = {
                comments = { italic = false }, 
                keywords = { italic = false },
            },
            -- transparent = true,
          }) 
        end
    },
}
