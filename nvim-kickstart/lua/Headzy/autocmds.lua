-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text (`:help vim.hl.on_yank()`)
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Apply clean settings when  with a scratch buffer
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    desc = "Remove Columns & Line Numbers on Nofile Buffers",
    group = vim.api.nvim_create_augroup("NoFileSetup", { clear = true }),
    pattern = { "*" },
    callback = function(args)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
        local nofile = args.file == "" or buftype == "nofile" or buftype == "terminal"
        if nofile then
            vim.o.number = false
            vim.o.relativenumber = false
            vim.o.signcolumn = "no"
        else
            vim.o.number = true
            vim.o.relativenumber = true
            vim.o.signcolumn = "yes"
        end
    end
})


-- TODO: FIGURE THIS OUT LATER
function txt_syntax()
    print("FIX THE FUNCTION PLZ :)")
    vim.cmd('syntax match DoubleQuote /"[^"]*"/')
    vim.cmd("syntax match SingleQuote /'[^']*'/")
    vim.cmd('syntax match AsteriskQuote /\\*\\zs[^*]\\+\\ze\\*/')

    -- Set colors for custom syntax highlighting
    vim.cmd('highlight DoubleQuote guifg=String')
    vim.cmd('highlight SingleQuote guifg=Comment')
    vim.cmd('highlight AsteriskQuote guifg=Todo')
end

-- vim.cmd[[
-- augroup CustomSyntax
--     autocmd!
--     autocmd FileType txt lua txt_syntax()
-- augroup END
-- ]]
