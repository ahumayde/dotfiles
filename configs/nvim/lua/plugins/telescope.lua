-- lua/plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  -- event = "VimEnter",
  -- branch = "0.1.x",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-tree/nvim-web-devicons" },
    { "nvim-telescope/telescope-ui-select.nvim" },
    { "nvim-telescope/telescope-fzf-native.nvim",
      -- If encountering errors, see telescope-fzf-native README for installation instructions
      build = "make",
      -- Condition if plugin should be installed & loaded
      cond = function() return vim.fn.executable "make" == 1 end,
    },
  },
  cmd = "Telescope",
  -- Plugin-specific keymaps live here, lazy-loaded via `keys`.
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<cr>" , desc = "[P]eek [F]iles" },
    { "<leader>pw", "<cmd>Telescope grep_string<cr>", desc = "[P]eek [W]ord" },
    { "<leader>pd", "<cmd>Telescope diagnostics<cr>", desc = "[P]eek [D]iagnostics" },

    { "<leader>pa", "<cmd>Telescope live_grep<cr>"  , desc = "[P]eek [A]ll Grep" },
    { "<leader>pg", "<cmd>Telescope live_grep<cr>"  , desc = "[P]eek [G]rep Live" },
    { "<leader>pl", "<cmd>Telescope live_grep<cr>"  , desc = "[P]eek [L]ive Grep" },

    { "<leader>pt", "<cmd>Telescope builtin<cr>"    , desc = "[P]eek [T]elescope" },
    { "<leader>ph", "<cmd>Telescope help_tags<cr>"  , desc = "[P]eek [H]elp" },
    { "<leader>pk", "<cmd>Telescope keymaps<cr>"    , desc = "[P]eek [K]eymaps" },

    { "<leader>po", "<cmd>Telescope oldfiles<cr>"   , desc = "[P]eek [O]ld Files" },
    { "<leader>pr", "<cmd>Telescope resume<cr>"     , desc = "[P]eek [R]esume" },
    { "<leader>pb", "<cmd>Telescope buffers<cr>"    , desc = "[P]eek [B]uffers" },

    { "<leader>pn", function()
      require("telescope.builtin").find_files({
         cwd = vim.fn.stdpath("config")
      }) end, desc = "[P]eek [N]eovim Files"
    },

    { "<leader>p.", function()
      require("telescope.builtin").find_files({
         hidden = true, no_ignore = true,
      }) end, desc = "[P]eek [.]Hidden Files"
    },

    { "<leader>ps", "<cmd>Telescope current_buffer_fuzzy_find<cr>"    , desc = "[P]eek [S]each" },
    -- { "<leader>ps", function()
    --   require("telescope.builtin").current_buffer_fuzzy_find(
    --     require("telescope.themes").get_dropdown({
    --       -- TODO: look into windblend = 10
    --
    --       previewer = false, winblend = 10,
    --   })) end, desc = "[P]eek [S]earch"
    -- },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        prompt_prefix = "  ",
        selection_caret = " ",
        mappings = { i = { ["<c-enter>"] = "to_fuzzy_refine" }, },
      },
      extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown(), }, },
    })
    pcall(telescope.load_extension, "fzf")
    pcall(require("telescope").load_extension, "ui-select")
  end,
}
