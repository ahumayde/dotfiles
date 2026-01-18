return {
    {
        "akinsho/flutter-tools.nvim",
        dependencies = {
            "plenary.nvim",
            "stevearc/dressing.nvim", -- optional for vim.ui.select
        },
        config = function()
            require("flutter-tools").setup({}) -- use defaults
        end,
    },
}
