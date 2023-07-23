require("neo-tree").setup{
    indent = {
            indent_size = 1,
            padding = 1,
    },
    window = {
          position = "left",
          width = 25,
          mapping_options = {
              noremap = true,
              nowait = true,
          },
    }
}

vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
vim.keymap.set("n", "<leader>m", ":Neotree toggle left<cr>")
-- vim.keymap.set("n", "<leader>m", ":Neotree toggle float<cr>")
