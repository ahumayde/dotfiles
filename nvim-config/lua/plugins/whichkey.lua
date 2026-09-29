-- lua\plugins\whichkey.lua
return { -- Which Key: Displays pending keybinds in a floating window.
    "folke/which-key.nvim",
    event = "VimEnter",
    opts = {
        delay = 0, -- delay between pressing a key and opening which-key (ms)
        icons = {
            mappings = vim.g.have_nerd_font,
            keys = vim.g.have_nerd_font and {} or {
                Up = "<Up> ", Down = "<Down> ", Left = "<Left> ", Right = "<Right> ",
                ScrollWheelDown = "<ScrollWheelDown> ",
                ScrollWheelUp = "<ScrollWheelUp> ",
                Space = "<Space> ", Tab = "<Tab> ",
                CR = "<CR> ", Esc = "<Esc> ",
                NL = "<NL> ", BS = "<BS> ",
                C = "<C-…> ", M = "<M-…> ",
                D = "<D-…> ", S = "<S-…> ",
                F1 = "<F1>", F2 = "<F2>", F3 = "<F3>",
                F4 = "<F4>", F5 = "<F5>", F6 = "<F6>",
                F7 = "<F7>", F8 = "<F8>", F9 = "<F9>",
                F10 = "<F10>", F11 = "<F11>", F12 = "<F12>",
            },
        },

        -- Document existing key chains
        spec = {
            { "<leader>p", group = "[P]eek" },
            { "<leader>r", group = "[R]esize" },
            { "<leader>t", group = "[T]oggle" },
            { "<leader>v", group = "[V]iew" },
            { "<leader>vd", group = "[V]iew [D]iagnostic" },
            { "<leader>q", group = "[QUIT] (forced)" },
            { "<leader>h", group = "Git [H]unk",                 mode = { "n", "v" } },
            -- FIX: This may not work
            { "<leader>n", group = "[N]avigate Window Commands", mode = { "n", "v" } },
        },
    },
}
