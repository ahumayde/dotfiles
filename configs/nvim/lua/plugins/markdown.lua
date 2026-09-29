return {
  "OXY2DEV/markview.nvim",
  lazy = false,
  -- Optional dependencies for icons and completion:
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- "saghen/blink.cmp", -- if using blink.cmp
  },
  opts = {
    preview = {
      icon_provider = "devicons", -- or "mini" / "internal"
    },
  },
}
