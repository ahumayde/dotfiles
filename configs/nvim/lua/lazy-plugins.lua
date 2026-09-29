-- lua/lazy-plugins.lua
-- Configure and run lazy.nvim's setup() with imported plugins

require("lazy").setup({
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
    spec = { -- Import every lua file in lua/plugins/
        { import = "plugins" },
    },
    install = { -- Colorscheme(s) to try loading before the first real UI paint
        colorscheme = { "vscode", "sorbet" },
    },
    checker = { -- Lazy Update auto-checker
        -- enabled = false,
        enabled = true,
    },
    ui = { -- Icons (w/o nerdfont)
        icons = vim.g.have_nerd_font and {} or {
            cmd = "⌘",
            config = "🛠",
            event = "📅",
            ft = "📂",
            init = "⚙",
            keys = "🗝",
            plugin = "🔌",
            runtime = "💻",
            require = "🌙",
            source = "📄",
            start = "🚀",
            task = "📌",
            lazy = "💤 ",
        },
    },
    performance = { -- Disable unused plugins
        rtp = {
            disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: set ts=2 sts=2 sw=2 et :
