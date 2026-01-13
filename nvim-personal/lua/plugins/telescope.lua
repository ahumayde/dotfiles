
local function fuzzyFindAfterMark()
    vim.api.nvim_command('normal! ms')
    require("telescope.builtin").current_buffer_fuzzy_find({})
end

return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "plenary" },
        config = function()
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
                        prompt_position = 'bottom',
                        -- horizontal = {
                        --     prompt_position = "top",
                        -- },
                    },
                    sorting_strategy = "descending",
                },
            }

            vim.keymap.set("n", "<leader>pi", builtin.git_files, {})
            vim.keymap.set("n", "<leader>pl", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>pa", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>pd", builtin.live_grep, {})
            vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
            vim.keymap.set("n", "<leader>ps", function() fuzzyFindAfterMark() end, {})
            vim.keymap.set("n", "<leader>pg", function() builtin.grep_string({ search = vim.fn.input("Grep > ") }); end)
            vim.keymap.set("n", "<leader>prr", function() builtin.grep_string({ search = vim.fn.expand("<cword>") }); end)
            vim.keymap.set("n", "<leader>pwr", function() builtin.grep_string({ search = vim.fn.expand("<cWORD>") }); end)
            vim.keymap.set("n", "<leader>ph", ":lua require('telescope.builtin').find_files({hidden=true})<CR>")
            vim.keymap.set("n", "<C-F>", function() fuzzyFindAfterMark() end, {})
            vim.keymap.set("n", "<C-S-F>", builtin.live_grep, {})
            vim.keymap.set("n", "<C-S-P>", builtin.find_files, {})
            vim.keymap.set("n", "<C-P>",   builtin.find_files, {})
        end
    },
}
