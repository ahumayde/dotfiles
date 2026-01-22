require("neo-tree").setup {
    filesystem = {
        filtered_items = {
           visible = true,
           hide_dotfiles = true,
           hide_gitignore = false,
        }
    },
    indent = {
        indent_size = 0,
        padding = 0,
    },
    window = {
        position = "left",
        width = 26,
        mapping_options = {
            noremap = true,
            nowait = true,
        },
        mappings = {
            ["P"] = { "toggle_preview", config = { use_float = false } },
        }
    }
}

vim.fn.sign_define("DiagnosticSignError", {text = " ", texthl = "DiagnosticSignError"})
vim.fn.sign_define("DiagnosticSignWarn", {text = " ", texthl = "DiagnosticSignWarn"})
vim.fn.sign_define("DiagnosticSignInfo", {text = " ", texthl = "DiagnosticSignInfo"})
vim.fn.sign_define("DiagnosticSignHint", {text = "󰌵", texthl = "DiagnosticSignHint"})

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>")
vim.keymap.set("n", "<leader>jf", ":Neotree toggle float<CR>")
vim.keymap.set('n', "<leader>m", ":Neotree reveal toggle<CR>", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>m", ":Neotree reveal toggle<CR>")
-- vim.keymap.set("n", "<leader>m", ":Neotree reveal_path reveal_force_cwd toggle<cr>")
-- vim.keymap.set("n", "<leader>m", ":Neotree toggle float<cr>")
