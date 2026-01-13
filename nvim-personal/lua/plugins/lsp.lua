---@diagnostic disable: undefined-field




return {
    -- 1. Plugin for configuring LSP servers
    {
        'neovim/nvim-lspconfig',
        dependencies = {

            -- Autocompletion
            -- "hrsh7th/nvim-cmp",
            -- "hrsh7th/cmp-path",
            -- "hrsh7th/cmp-buffer",
            -- "hrsh7th/cmp-nvim-lsp",
            -- "hrsh7th/cmp-nvim-lua",
            -- "saadparwaiz1/cmp_luasnip",
            { "saghen/blink.cmp" },
            -- Snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },
        },

        config = function()
            -- lsp.preset("recommended")
            -- local cmp_select = { behavior = cmp.SelectBehavior.Select }

            -- cmp.setup({
            -- mapping = cmp.mapping.preset.insert({
            --     ['<C-Space>'] = cmp.mapping.complete(),
            --     ['<C-f>'] = cmp_action.luasnip_jump_forward(),
            --     ['<C-b>'] = cmp_action.luasnip_jump_backward(),
            --   })
            -- })
            --
            -- local cmp_mappings = vim.lsp.defaults.cmp_mappings({
            -- ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),
            -- ['<A-j>'] = cmp.mapping.select_next_item(cmp_select),
            -- ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
            -- ['<A-k>'] = cmp.mapping.select_prev_item(cmp_select),
            -- ['<C-y>'] = cmp.mapping.confirm({ select = true }),
            -- ['<A-y>'] = cmp.mapping.confirm({ select = true }),
            -- ["<A-f>"] = cmp.mapping.complete(),
            -- ["<C-f>"] = cmp.mapping.complete(),
            -- ["<C-Space>"] = cmp.mapping.complete(), -- Enter
            -- })
            -- cmp_mappings['<Tab>'] = nil
            -- cmp_mappings['<S-Tab>'] = nil

            --[[ lsp.setup_nvim_cmp({
                mapping = cmp_mappings
            })

            lsp.set_preferences({
                suggest_lsp_servers = false,
                sign_icons = {
                    error = 'E',
                    warn  = 'W',
                    hint  = 'H',
                    info  = 'I'
                }
            }) ]]

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local opts = { buffer = args.buf, remap = false }
                    -- lsp.default_keymaps({ buffer = bufnr })

                    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
                    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
                    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
                    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
                    vim.keymap.set("n", "<leader>vdi", function() vim.diagnostic.open_float() end, opts)

                    -- Not Using
                    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
                    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
                    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)

                    -- vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
                    -- vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
                end
            })

            vim.keymap.set({ "n", "x" }, "<leader>vdc", ":lua vim.diagnostic.config({virtual_text = false})<CR>")
            vim.keymap.set({ "n", "x" }, "<leader>vdo", ":lua vim.diagnostic.config({virtual_text = true})<CR>")
            vim.keymap.set({ "n", "x" }, "<leader>vf", ":lua vim.lsp.buf.format({async = false, timeout_ms = 10000})<CR>")

            -- lsp.setup()

            --[[ vim.diagnostic.config({
                virtual_text = false
            }) ]]

            local warnings = {
                'E203', -- Whitespace before colon
                'E221', -- Multiple spaces before operator
                -- 'E223', -- Whitespace before operator
                -- 'E225', -- Missing whitespace around operator
                'E226', -- Missing whitespace around arithmetic operator
                'E231', -- Missing whitespace after ','
                -- 'E301', -- Expected 1 blank line, found 0
                -- 'E302', -- Expected 2 blank lines, found 0
                -- 'E303', -- Too many blank lines (3)
                'E501', -- Line too long (max-line-length)
                -- 'E503', -- Line break occurred before a binary operator
                -- 'W291', -- Trailing whitespace
                -- 'W293', -- Blank line contains whitespace
                -- 'F403', -- 'from module import *' used; unable to detect undefined names
                -- 'F405', -- 'foo.bar' may be undefined, or defined from star imports
            }

            local servers = {
                --[[ pylsp = {
                    settings = {
                        pylsp = {
                            plugins = {
                                pyflakes = {
                                    enabled = false,
                                },
                                flake8 = {
                                    ignore = warnings,
                                },
                                pycodestyle = {
                                    ignore = warnings,
                                },
                                pydocstyle = {
                                    ignore = warnings,
                                },
                                pylint = {
                                    ignore = warnings,
                                },
                            },
                        },
                    },
                }, ]]

                lua_ls = {
                    on_init = function(client)
                        if client.workspace_folders then
                            local path = client.workspace_folders[1].name
                            if path ~= vim.fn.stdpath('config')
                                and (vim.uv.fs_stat(path .. '/.luarc.json')
                                    or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                            then
                                return
                            end
                        end

                        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                            runtime = {
                                version = 'LuaJIT',
                                path = { 'lua/?.lua', 'lua/?/init.lua', },
                            },

                            workspace = {
                                checkThirdParty = false,
                                library = { vim.env.VIMRUNTIME }
                                -- library = vim.api.nvim_get_runtime_file("", true)
                            }
                        })
                    end,

                    settings = {
                        Lua = {
                            format = {
                                indent_style = 'space',
                                indent_size = 4,
                                tab_stop = 4,
                            }
                        }
                    },
                }
            }

            for server, config in pairs(servers) do
                local blink = require("blink.cmp")
                config.capabilities = blink.get_lsp_capabilities(config.capabilities)
                vim.lsp.config(server, config)
            end

            vim.lsp.enable("lua_ls")
        end,
    },

    { -- Autocompletion
        "saghen/blink.cmp",
        event = "VimEnter",
        version = "1.*",
        dependencies = {
            -- Snippet Engine
            {
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
                    {
                      "rafamadriz/friendly-snippets",
                      config = function()
                        require("luasnip.loaders.from_vscode").lazy_load()
                      end,
                    },
                },
                opts = {},
            },
            "folke/lazydev.nvim",
        },
        opts = {
            keymap = {
                preset = "default",
            },

            appearance = {
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


    -- 2. Optional: Basic Mason-LSP setup for supported servers

    -- { "hrsh7th/cmp-nvim-lsp" },

    -- {
    -- "williamboman/mason-lspconfig.nvim",
    -- config = function()
    -- vim.lsp.config().lua_ls.setup({
    --     cmd = { "/data/data/com.termux/files/usr/bin/lua-language-server" },
    -- })
    -- end
    -- },

    -- LSP Zero
    --[[ {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v1.x",
        requires = {
            -- LSP Support
            { "neovim/nvim-lspconfig" },
            { "williamboman/mason.nvim" },
            { "williamboman/mason-lspconfig.nvim" },

            -- Autocompletion
            { "hrsh7th/nvim-cmp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lua" },

            -- Snippets
            { "L3MON4D3/LuaSnip" },
            { "rafamadriz/friendly-snippets" },

        }
    }, ]]
}
