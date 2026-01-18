return {
    { 
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        opts = {
            ensure_installed = {
                "c", "lua", "luadoc", "vim", "vimdoc", "dart",
                "cpp", "python", "javascript", "typescript",
                "bash", "powershell", "arduino", "verilog", 
                "markdown", "markdown_inline", "query",
            },
            sync_install = false,
            auto_install = true,
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = { "ruby", "markdown" },
            },
            indent = { enable = true, disable = { "ruby" } },
            context_commentstring = { enable = true, },
        }
    },

    { "nvim-treesitter/nvim-treesitter-context" },
}
