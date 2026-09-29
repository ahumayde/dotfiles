-- lua/plugins/statusline.lua

return {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    init = function()
        vim.api.nvim_create_autocmd('ColorScheme', {
            pattern = '*',
            callback = function()
                local statusline   = vim.api.nvim_get_hl(0, { name = 'StatusLine' })
                local statuslinenc = vim.api.nvim_get_hl(0, { name = 'StatusLineNC' })
                statusline.bg   = 'NONE'
                statuslinenc.bg = 'NONE'
                vim.api.nvim_set_hl(0, 'StatusLine', statusline)
                vim.api.nvim_set_hl(0, 'StatusLineNC', statuslinenc)
            end,
        })
    end,
    opts = function()
        -- local custom_theme = require('lualine.themes.auto')
        local theme = require('lualine.themes.auto')

        -- 1. Outer edges (lualine_a and lualine_z)
        theme.normal.a.bg   = '#0077CC'
        theme.insert.a.bg   = '#44CC77'
        theme.visual.a.bg   = '#9966FF'
        theme.replace.a.bg  = '#F1F1A1'
        theme.command.a.bg  = '#F84848'
        theme.terminal.a.bg = '#181B1F'

        theme.normal.a.fg   = 'NONE'
        theme.insert.a.fg   = 'NONE'
        theme.visual.a.fg   = 'NONE'
        theme.replace.a.fg  = 'NONE'
        theme.command.a.fg  = 'NONE'
        theme.terminal.a.fg = '#44CC77'

        -- 2. Inner transitions (lualine_b and lualine_y)
        theme.normal.b.bg   = 'NONE'
        theme.insert.b.bg   = 'NONE'
        theme.visual.b.bg   = 'NONE'
        theme.replace.b.bg  = 'NONE'
        theme.command.b.bg  = 'NONE'
        theme.terminal.b.bg = 'NONE'

        theme.normal.b.fg   = 'NONE'
        theme.insert.b.fg   = 'NONE'
        theme.visual.b.fg   = 'NONE'
        theme.replace.b.fg  = 'NONE'
        theme.command.b.fg  = 'NONE'
        theme.terminal.b.fg = 'NONE'

        -- 4. Inactive windows (when you split your screen)
        theme.inactive.a.bg = 'NONE'
        theme.inactive.b.bg = 'NONE'
        theme.inactive.c.bg = 'NONE'
        theme.inactive.a.fg = 'NONE'
        theme.inactive.b.fg = 'NONE'
        theme.inactive.c.fg = 'NONE'


        return {
            options = {
                theme = theme,
                icons_enabled = true,
                component_separators = '',
                section_separators = { left = '', right = ''},
            },
            sections = {
                lualine_a = { {
                    'mode', separator = { left = '', right = '' },
                    padding = { left = 0, right = 0 },
                } },
                lualine_b = { { 'filename', path = 1 } },
                lualine_c = {},

                lualine_x = {},
                lualine_y = {
                    'fileformat',
                    { 'branch', color = { fg = '#7744FF', gui = 'bold' } },
                    'diff', 'diagnostics', 'filetype', 'progress'
                },

                lualine_z = { {
                    'location', separator = { left = '', right = '' },
                    padding = { left = 0, right = 0 },
                } },
            },
        }
    end
}
