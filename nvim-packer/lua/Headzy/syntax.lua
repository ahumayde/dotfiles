-- FIGURE THIS OUT LATER



function Txt_syntax()
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
--     autocmd FileType txt lua Txt_syntax()
-- augroup END
-- ]]
