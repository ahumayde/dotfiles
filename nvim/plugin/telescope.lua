local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

require("telescope").setup {
    defaults = {
        mappings = {
            i = {
                ["<A-j>"] = actions.move_selection_next,
                ["<C-j>"] = actions.move_selection_next,
                ["<A-k>"] = actions.move_selection_previous,
                ["<C-k>"] = actions.move_selection_previous,
            },
        },
        layout_config = {
            horizontal = {
                prompt_position = "top",
            }
        },
        sorting_strategy = "ascending",
    },
}

local function fuzzyFindAfterMark()
    vim.api.nvim_command('normal! ms')
    builtin.current_buffer_fuzzy_find({})
end

vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
vim.keymap.set("n", "<leader>pi", builtin.git_files, {})
vim.keymap.set("n", "<leader>pl", builtin.live_grep, {})
vim.keymap.set("n", "<leader>ps", function() fuzzyFindAfterMark() end, {})
vim.keymap.set("n", "<leader>pg", function() builtin.grep_string({ search = vim.fn.input("Grep > ") }); end)
vim.keymap.set("n", "<leader>ph", ":lua require('telescope.builtin').find_files({hidden=true})<CR>")
