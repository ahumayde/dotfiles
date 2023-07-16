local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<leader>pi', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', builtin.current_buffer_fuzzy_find, {})
vim.keymap.set('n', '<leader>pl', builtin.live_grep, {})
vim.keymap.set('n', '<leader>pg', function()
	builtin.grep_string( { search = vim.fn.input("Grep > ") });
end)
