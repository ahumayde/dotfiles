require('Comment').setup {
    toggler  = {
        line = '<C-_>',
        -- line = 'gcc',
        block = 'gbc'
    },
    opleader = {
        line = '<C-_>',
        -- line = 'gc',
        block = 'gb'
    },
    mappings = {
        basic = true,
        extra = true,
    },
}

-- gcA  - Insert comment to end of the current line and enters INSERT mode
-- gb$  - Toggle from the current cursor position to the end of line

-- gcip - Toggle inside of paragraph
-- gc}  - Toggle until the next blank line
-- gca} - Toggle around curly brackets

-- gbaf - Toggle comment around a function
-- gbac - Toggle comment around a class

-- gco  - Insert comment to the next line and enters INSERT mode
-- gcO  - Insert comment to the previous line and enters INSERT mode

-- gcw  - Toggle from the current cursor position to the next word

-- :h comment.config
