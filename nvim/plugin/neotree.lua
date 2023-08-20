require("neo-tree").setup {
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

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
vim.keymap.set("n", "<leader>m", ":Neotree reveal toggle<cr>")
-- vim.keymap.set("n", "<leader>m", ":Neotree reveal_path reveal_force_cwd toggle<cr>")
-- vim.keymap.set("n", "<leader>m", ":Neotree toggle float<cr>")
