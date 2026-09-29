-- lua/plugins/colorscheme.lua

return {
    {-- VSCode: Colourscheme
        "Mofiqul/vscode.nvim",
        name = "vscode",
        lazy = false,
        priority = 1000,
        config = function()
            require('vscode').setup({
                transparent = true,
                underline_links = true,
                disable_nvimtree_bg = true,
                terminal_colors = true,
                color_overrides = {
                    vscBlue = '#4FC1FF',
                    vscAccentBlue = '#4FC1FF',
                    vscMediumBlue = '#18A2FE',
                    vscDisabledBlue = '#729DB3',
                    vscLineNumber = "#FFFFFF",
                }
            })
            vim.cmd.colorscheme("vscode")
        end
    },

    {-- TokyoNight: Colourscheme
        "folke/tokyonight.nvim",
        -- lazy = false, -- load on startup
        -- priority = 1000, -- load before other plugins
        opts = { style = "night", },
        config = function(_, opts)
            require("tokyonight").setup(opts)
            -- vim.cmd.colorscheme("tokyonight")
        end,
    },
}
