-- lua/plugins/completion.lua
-- blink.cmp: fast, minimal-config completion engine. Swap for nvim-cmp
-- here if you prefer it -- nothing else in the config depends on which
-- one you pick, aside from lsp.lua's `get_lsp_capabilities()` call.
return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "*",
  opts = {
    keymap = { preset = "default" },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
