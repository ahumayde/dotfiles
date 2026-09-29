-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    -- Add/remove languages as you need them.
    ensure_installed = {
      "lua", "vim", "vimdoc", "query",
      "bash", "markdown", "markdown_inline",
      "zig", "python", "javascript", "typescript", "json", "yaml",
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function(_, opts)
    -- 1. Set the compiler first
    require('nvim-treesitter.install').compilers = { "zig" }

    -- 2. Run setup so parsers compile using Zig
    require("nvim-treesitter.configs").setup(opts)
  end,
}
