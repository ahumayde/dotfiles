--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

  NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')


-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
        -- error("Error cloning lazy.nvim:\n" .. out)
    end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.

require("lazy").setup({
    spec = {
        -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
        { "NMAC427/guess-indent.nvim", }, -- Detect tabstop and shiftwidth automatically

        -- NOTE: Plugins can also be added by using a table,
        -- with the first argument being the link and the following
        -- keys can be used to configure plugin behavior/loading/etc.
        --
        -- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.

        -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
        --
        -- which loads which-key before all the UI elements are loaded. Events can be
        -- normal autocommands events (`:help autocmd-events`).
        { -- Which Key: Displays pending keybinds in a floating window.
            "folke/which-key.nvim",
            event = "VimEnter",
            opts = {
                delay = 0, -- delay between pressing a key and opening which-key (ms)
                icons = {
                    mappings = vim.g.have_nerd_font,
                    keys = vim.g.have_nerd_font and {} or {
                        Up = "<Up> ",
                        Down = "<Down> ",
                        Left = "<Left> ",
                        Right = "<Right> ",
                        C = "<C-…> ",
                        M = "<M-…> ",
                        D = "<D-…> ",
                        S = "<S-…> ",
                        CR = "<CR> ",
                        Esc = "<Esc> ",
                        ScrollWheelDown = "<ScrollWheelDown> ",
                        ScrollWheelUp = "<ScrollWheelUp> ",
                        NL = "<NL> ",
                        BS = "<BS> ",
                        Space = "<Space> ",
                        Tab = "<Tab> ",
                        F1 = "<F1>",
                        F2 = "<F2>",
                        F3 = "<F3>",
                        F4 = "<F4>",
                        F5 = "<F5>",
                        F6 = "<F6>",
                        F7 = "<F7>",
                        F8 = "<F8>",
                        F9 = "<F9>",
                        F10 = "<F10>",
                        F11 = "<F11>",
                        F12 = "<F12>",
                    },
                },

                -- Document existing key chains
                spec = {
                    { "<leader>p", group = "[P]eek" },
                    { "<leader>t", group = "[T]oggle" },
                    { "<leader>h", group = "Git [H]unk",                 mode = { "n", "v" } },
                    -- FIX: This may not work
                    { "<leader>n", group = "[N]avigate Window Commands", mode = { "n", "v" } },
                },
            },
        },

        { -- Telescope: Fuzzy Finder (files, lsp, keymaps, etc)
            "nvim-telescope/telescope.nvim",
            event = "VimEnter",
            dependencies = {
                { "nvim-lua/plenary.nvim" },
                { "nvim-tree/nvim-web-devicons",            enabled = vim.g.have_nerd_font },
                { "nvim-telescope/telescope-ui-select.nvim" },
                {
                    -- If encountering errors, see telescope-fzf-native README for installation instructions
                    "nvim-telescope/telescope-fzf-native.nvim",
                    build = "make",

                    -- Condition if plugin should be installed & loaded
                    cond = function() return vim.fn.executable "make" == 1 end,
                },
            },
            config = function()
                -- TODO: Figure this out:
                -- Two important keymaps to use while in Telescope are:
                --  - Insert mode: <c-/>
                --  - Normal mode: ?
                --

                -- [[ Configure Telescope ]] (`:help telescope`, `:help telescope.setup()`)
                require("telescope").setup {
                    -- TODO: Look into these
                    defaults = { mappings = { i = { ["<c-enter>"] = "to_fuzzy_refine" }, }, },
                    extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown(), }, },
                    -- Telescope picker. This is really useful to discover what Telescope can
                    -- do as well as how to actually do it!
                    -- pickers = {}
                }

                -- Enable Telescope extensions if they are installed
                pcall(require("telescope").load_extension, "fzf")
                pcall(require("telescope").load_extension, "ui-select")

                -- See `:help telescope.builtin`
                local builtin = require "telescope.builtin"
                -- TODO: Edit these, e.g. pl/pa etc <C-P>
                vim.keymap.set("n", "<leader>ph", builtin.help_tags, { desc = "[P]eek [H]elp" })
                vim.keymap.set("n", "<leader>pk", builtin.keymaps, { desc = "[P]eek [K]eymaps" })
                vim.keymap.set("n", "<leader>pf", builtin.find_files, { desc = "[P]eek [F]iles" })
                vim.keymap.set("n", "<leader>pt", builtin.builtin, { desc = "[P]eek [T]elescope" })
                vim.keymap.set("n", "<leader>pw", builtin.grep_string, { desc = "[P]eek current [W]ord" })
                vim.keymap.set("n", "<leader>pg", builtin.live_grep, { desc = "[P]eek by [G]rep" })
                vim.keymap.set("n", "<leader>pd", builtin.diagnostics, { desc = "[P]eek [D]iagnostics" })
                vim.keymap.set("n", "<leader>pr", builtin.resume, { desc = "[P]eek [R]esume" })
                vim.keymap.set("n", "<leader>p.", builtin.oldfiles, { desc = "[P]eek Recent Files ([.] for repeat)" })
                vim.keymap.set("n", "<leader>pb", builtin.buffers, { desc = "[P]eek [B]uffers" })

                vim.keymap.set("n", "<leader>pn", function()
                    builtin.find_files { cwd = vim.fn.stdpath "config" }
                end, { desc = "[P]eek [N]eovim files" })

                vim.keymap.set("n", "<leader>ps", function()
                    builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
                        -- TODO: windblend was commented - look into it
                        previewer = false, winblend = 10,
                    })
                end, { desc = "[P] Fuzzily [S]earch in current buffer" })

                vim.keymap.set("n", "<leader>p/", function()
                    builtin.live_grep {
                        grep_open_files = true,
                        prompt_title = "Live Grep in Open Files",
                    }
                end, { desc = "[P]eek Open Files ([/] for search)" })
            end,
        },

        -- LSP Plugins --

        { -- LazyDev
            -- TODO: Look into this
            -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
            -- used for completion, annotations and signatures of Neovim apis
            "folke/lazydev.nvim",
            ft = "lua",
            opts = {
                library = {
                    -- Load luvit types when the `vim.uv` word is found
                    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                },
            },
        },

        { -- Nvim LSP Config: Main LSP Configuration
            -- LSP vs Treesitter - (`:help lsp-vs-treesitter`)
            "neovim/nvim-lspconfig",
            dependencies = {
                -- LSP Source Plugins
                { 'dart-lang/dart-vim-plugin' },

                -- Mason: must be loaded before its dependents so we need to set it up here.
                { "mason-org/mason.nvim",                     opts = {} },
                { "mason-org/mason-lspconfig.nvim" },
                { "WhoIsSethDaniel/mason-tool-installer.nvim" },

                { -- Fidget: Useful status updates for LSP.
                    "j-hui/fidget.nvim",
                    event = "LspAttach",
                    opts = {
                        display = { done_ttl = 0.01, },
                        progress = {
                            suppress_on_insert = true,
                            ignore_empty_message = true,
                            ignore = {
                                function(msg) return msg.title == "Diagnosing" end,
                                -- Other functions or LSP Server (str)
                            }
                        },
                    },
                },

                -- Blink: Allows extra capabilities provided by blink.cmp
                -- TODO: Look into this
                { "saghen/blink.cmp" },
            },

            config = function()
                -- LSP Keymaps:
                -- TODO: Edit these keymaps
                vim.api.nvim_create_autocmd("LspAttach", {
                    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                    callback = function(event)
                        local map = function(keys, func, desc, mode)
                            mode = mode or "n"
                            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                        end

                        map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
                        map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
                        map("gca", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
                        map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
                        map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
                        map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
                        map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                        -- Fuzzy find all the symbols in your current document.
                        --  Symbols are things like variables, functions, types, etc.
                        map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")

                        -- Fuzzy find all the symbols in your current workspace.
                        --  Similar to document symbols, except searches over your entire project.
                        map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")

                        -- Jump to the type of the word under your cursor.
                        --  Useful when you're not sure what type a variable is and you want to see
                        --  the definition of its *type*, not where it was *defined*.
                        map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

                        -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
                        ---@param client vim.lsp.Client
                        ---@param method vim.lsp.protocol.Method
                        ---@param bufnr? integer some lsp support methods only in specific files
                        ---@return boolean
                        local function client_supports_method(client, method, bufnr)
                            if vim.fn.has "nvim-0.11" == 1 then
                                return client:supports_method(method, bufnr)
                            else
                                return client.supports_method(method, { bufnr = bufnr })
                            end
                        end

                        -- Highlights references of word under cursor (`:help CursorHold`)
                        local client = vim.lsp.get_client_by_id(event.data.client_id)
                        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
                            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight",
                                { clear = false })

                            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                                buffer = event.buf,
                                group = highlight_augroup,
                                callback = vim.lsp.buf.document_highlight,
                            })

                            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                                buffer = event.buf,
                                group = highlight_augroup,
                                callback = vim.lsp.buf.clear_references,
                            })

                            vim.api.nvim_create_autocmd("LspDetach", {
                                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                                callback = function(event2)
                                    vim.lsp.buf.clear_references()
                                    vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
                                end,
                            })
                        end

                        -- Type Hints: toggles inlay type hints (ghost text) in code buffer
                        -- TODO: Resolve Keymap for this feature
                        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
                            map("<leader>th", function()
                                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                            end, "[T]oggle Inlay [H]ints")
                        end
                    end,
                })

                -- Diagnostic Config (`:help vim.diagnostic.Opts`)
                vim.diagnostic.config {
                    severity_sort = true,
                    float = { border = "rounded", source = "if_many" },
                    underline = { severity = vim.diagnostic.severity.ERROR },
                    signs = vim.g.have_nerd_font and {
                        text = {
                            [vim.diagnostic.severity.HINT]  = "H ",
                            [vim.diagnostic.severity.INFO]  = "I ",
                            [vim.diagnostic.severity.WARN]  = "W ",
                            [vim.diagnostic.severity.ERROR] = "E ",
                        },
                    } or {},
                    virtual_text = {
                        source = "if_many",
                        spacing = 2,
                        format = function(diagnostic)
                            local diagnostic_message = {
                                [vim.diagnostic.severity.ERROR] = diagnostic.message,
                                [vim.diagnostic.severity.WARN] = diagnostic.message,
                                [vim.diagnostic.severity.INFO] = diagnostic.message,
                                [vim.diagnostic.severity.HINT] = diagnostic.message,
                            }
                            return diagnostic_message[diagnostic.severity]
                        end,
                    },
                }

                -- Blink creates new LSP Capabilities for Neovim and broadcasts them to the servers
                local capabilities = require("blink.cmp").get_lsp_capabilities()

                --  Add any additional override configuration in the following tables. Available keys are:
                --  - cmd (table): Override the default command used to start the server
                --  - filetypes (table): Override the default list of associated filetypes for the server
                --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
                --  - settings (table): Override the default settings passed when initializing the server.
                --  `:help lspconfig-all`
                local servers = {
                    -- clangd = {},
                    -- gopls = {},
                    -- pyright = {},
                    -- rust_analyzer = {},
                    -- ts_ls = {},
                    -- dart_lang = {},

                    -- Options: `https://luals.github.io/wiki/settings/`
                    -- lua_ls = {
                    --   -- cmd = { ... },
                    --   -- filetypes = { ... },
                    --   -- capabilities = {},
                    --   settings = {
                    --     Lua = {
                    --       format = {
                    --         indent_style = 'space',
                    --         indent_size = 4,
                    --         tab_stop = 4,
                    --       },
                    --
                    --       completion = {
                    --         callSnippet = "Replace",
                    --       },
                    --       -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                    --       -- diagnostics = { disable = { "missing-fields" } },
                    --     },
                    --   },
                    -- },
                }

                -- Ensure the servers and tools above are installed
                -- `mason` had to be setup earlier: to configure its options see the
                -- `dependencies` table for `nvim-lspconfig` above.
                local ensure_installed = vim.tbl_keys(servers or {})
                vim.list_extend(ensure_installed, { --[[ "stylua", -- Used to format Lua code ]] })
                require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

                require("mason-lspconfig").setup({
                    ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
                    automatic_installation = false,
                    handlers = {
                        function(server_name)
                            local server = servers[server_name] or {}
                            -- This handles overriding only values explicitly passed
                            -- by the server configuration above. Useful when disabling
                            -- certain features of an LSP (for example, turning off formatting for ts_ls)
                            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities,
                                server.capabilities or {})
                            require("lspconfig")[server_name].setup(server)
                        end,
                    },
                })

                vim.lsp.config("lua_ls", {
                    settings = {
                        Lua = {
                            format = {
                                indent_style = 'space',
                                indent_size = 4,
                                tab_stop = 4,
                            }
                        }
                    }
                })
            end,
        },

        --[[ { -- Conform: Automatic Formatter
            "stevearc/conform.nvim",
            event = { "BufWritePre" },
            cmd = { "ConformInfo" },

            keys = {
                {
                    "<leader>f",
                    mode = "",
                    desc = "[F]ormat buffer",
                    function()
                        require("conform").format({
                            async = true, lsp_format = "fallback"
                        })
                    end,
                },
            },

            opts = {
                notify_on_error = false,
                format_on_save = function(bufnr)
                    -- Disable "format_on_save lsp_fallback" for languages that don't
                    -- have a well standardized coding style. You can add additional
                    -- languages here or re-enable it for the disabled ones.
                    local disable_filetypes = { c = true, cpp = true }
                    if disable_filetypes[vim.bo[bufnr].filetype] then
                        return nil
                    else
                        return {
                            timeout_ms = 500,
                            lsp_format = "fallback",
                        }
                    end
                end,
                formatters_by_ft = {
                    lua = { "stylua" },
                    -- Conform can also run multiple formatters sequentially
                    -- python = { "isort", "black" },
                    --
                    -- You can use "stop_after_first" to run the first available formatter from the list
                    -- javascript = { "prettierd", "prettier", stop_after_first = true },
                },
            },
        }, ]]

        { -- Blink: Autocompletion
            "saghen/blink.cmp",
            event = "VimEnter",
            version = "1.*",
            dependencies = {
                { -- LuaSnip: Snippet Engine
                    "L3MON4D3/LuaSnip",
                    version = "2.*",
                    build = (function()
                        -- Build Step is needed for regex support in snippets.
                        -- This step is not supported in many windows environments.
                        -- Remove the below condition to re-enable on windows.
                        if vim.fn.has "win32" == 1 or vim.fn.executable "make" == 0 then
                            return
                        end
                        return "make install_jsregexp"
                    end)(),
                    dependencies = {
                        -- `friendly-snippets` contains a variety of premade snippets.
                        --    See the README about individual language/framework/plugin snippets:
                        --    https://github.com/rafamadriz/friendly-snippets
                        -- {
                        --   "rafamadriz/friendly-snippets",
                        --   config = function()
                        --     require("luasnip.loaders.from_vscode").lazy_load()
                        --   end,
                        -- },
                    },
                    opts = {},
                },
                "folke/lazydev.nvim",
            },
            --- @module "blink.cmp"
            --- @type blink.cmp.Config
            opts = {
                keymap = {
                    -- "default" (recommended) for mappings similar to built-in completions
                    --   <c-y> to accept ([y]es) the completion.
                    --    This will auto-import if your LSP supports it.
                    --    This will expand snippets if the LSP sent a snippet.
                    -- "super-tab" for tab to accept
                    -- "enter" for enter to accept
                    -- "none" for no mappings
                    --
                    -- For an understanding of why the "default" preset is recommended,
                    -- you will need to read `:help ins-completion`
                    --
                    -- No, but seriously. Please read `:help ins-completion`, it is really good!
                    --
                    -- All presets have the following mappings:
                    -- <tab>/<s-tab>: move to right/left of your snippet expansion
                    -- <c-space>: Open menu or open docs if already open
                    -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                    -- <c-e>: Hide menu
                    -- <c-k>: Toggle signature help
                    --
                    -- See :h blink-cmp-config-keymap for defining your own keymap
                    preset = "default",

                    -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                    --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
                },

                appearance = {
                    -- "mono" (default) for "Nerd Font Mono" or "normal" for "Nerd Font"
                    -- Adjusts spacing to ensure icons are aligned
                    nerd_font_variant = "mono",
                },

                completion = {
                    -- By default, you may press `<c-space>` to show the documentation.
                    -- Optionally, set `auto_show = true` to show the documentation after a delay.
                    documentation = { auto_show = false, auto_show_delay_ms = 500 },
                },

                sources = {
                    default = { "lsp", "path", "snippets", "lazydev" },
                    providers = {
                        lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
                    },
                },

                snippets = { preset = "luasnip" },

                -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
                -- which automatically downloads a prebuilt binary when enabled.
                --
                -- By default, we use the Lua implementation instead, but you may enable
                -- the rust implementation via `"prefer_rust_with_warning"`
                --
                -- See :h blink-cmp-config-fuzzy for more information
                fuzzy = { implementation = "lua" },

                -- Shows a signature help window while you type arguments for a function
                signature = { enabled = true },
            },
        },

        { -- Tokyonight: Colourscheme
            "folke/tokyonight.nvim",
            priority = 1000,
            config = function()
                ---@diagnostic disable-next-line: missing-fields
                require("tokyonight").setup {
                    styles = {
                        comments = { italic = false }, -- Disable italics in comments
                        keywords = { italic = false }, -- Disable italics in keywords
                    },
                }
            end,
        },

        { -- VSCode: Colourscheme
            "Mofiqul/vscode.nvim",
            name = "vscode",
            priority = 1000,
            config = function()
                -- ColourVim()
                vim.cmd.colorscheme("vscode")
            end
        },

        -- Todo Comments: Highlight todo, note, warn, fix, etc in comments
        { "folke/todo-comments.nvim",  event = "VimEnter", dependencies = { "nvim-lua/plenary.nvim" }, opts = { signs = false } },

        { -- Mini: Better Around/Inside textobjects
            "echasnovski/mini.nvim",
            config = function()
                -- Examples:
                --  - va)  - [V]isually select [A]round [)]paren
                --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
                --  - ci'  - [C]hange [I]nside [']quote
                require("mini.ai").setup({ n_lines = 500 })

                -- Add/delete/replace surroundings (brackets, quotes, etc.)
                -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
                -- - sd'   - [S]urround [D]elete [']quotes
                -- - sr)'  - [S]urround [R]eplace [)] [']
                require("mini.surround").setup()

                -- Simple and easy statusline.
                --  You could remove this setup call if you don't like it,
                --  and try some other statusline plugin
                local statusline = require("mini.statusline")
                -- set use_icons to true if you have a Nerd Font
                statusline.setup({ use_icons = vim.g.have_nerd_font })

                -- You can configure sections in the statusline by overriding their
                -- default behavior. For example, here we set the section for
                -- cursor location to LINE:COLUMN
                ---@diagnostic disable-next-line: duplicate-set-field
                statusline.section_location = function() return "%2l:%-2v" end

                -- ... and there is more!
                --  Check out: https://github.com/echasnovski/mini.nvim
            end,
        },

        { -- Highlight, edit, and navigate code
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            main = "nvim-treesitter.configs", -- Sets main module to use for opts
            -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
            opts = {
                ensure_installed = { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "markdown_inline", "query", "vim", "vimdoc", "dart" },
                -- Autoinstall languages that are not installed
                auto_install = true,
                highlight = {
                    enable = true,
                    -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
                    --  If you are experiencing weird indenting issues, add the language to
                    --  the list of additional_vim_regex_highlighting and disabled languages for indent.
                    additional_vim_regex_highlighting = { "ruby" },
                },
                indent = { enable = true, disable = { "ruby" } },
            },
            -- There are additional nvim-treesitter modules that you can use to interact
            -- with nvim-treesitter. You should go explore a few and see what interests you:
            --
            --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
            --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
            --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
        },

        -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
        -- init.lua. If you want these files, they are in the repository, so you can just download them and
        -- place them in the correct locations.

        -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
        --
        --  Here are some example plugins that I've included in the Kickstart repository.
        --  Uncomment any of the lines below to enable them (you will need to restart nvim).
        --
        -- require "kickstart.plugins.debug",
        -- require "kickstart.plugins.indent_line",
        -- require "kickstart.plugins.lint",
        -- require "kickstart.plugins.autopairs",
        -- require "kickstart.plugins.neo-tree",
        -- require "kickstart.plugins.gitsigns", -- adds gitsigns recommend keymaps

        -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
        --    This is the easiest way to modularize your config.
        --
        --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
        { import = "plugins" },

        -- If you are using a Nerd Font: set icons to an empty table which will use the
        -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table

        -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
        -- Or use telescope!
        -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
        -- you can continue same window with `<space>sr` which resumes last telescope search
    },

    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    ui = {
        icons = vim.g.have_nerd_font and {} or {
            cmd = "⌘",
            config = "🛠",
            event = "📅",
            ft = "📂",
            init = "⚙",
            keys = "🗝",
            plugin = "🔌",
            runtime = "💻",
            require = "🌙",
            source = "📄",
            start = "🚀",
            task = "📌",
            lazy = "💤 ",
        },
    },
    install = { colorscheme = { "vscode" } },
    change_detection = { enabled = false, notify = false, }
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- nim: ts=2 sts=2 sw=2 et
