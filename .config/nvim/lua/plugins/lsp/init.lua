local au = vim.api.nvim_create_augroup('LspAttach', { clear = true })
return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        init = function()
            local lsp = {}
            -- client log level
            vim.lsp.set_log_level(vim.lsp.log_levels.INFO)

            local signs = {
                Error = '', -- ◉
                Warn = '', -- ●
                Info = '', -- •
                Hint = '', -- ·
            }
            for severity, icon in pairs(signs) do
                local hl = 'DiagnosticSign' .. severity
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
            end

            vim.diagnostic.config {
                underline = true,
                signs = {
                    severity = { min = vim.diagnostic.severity.WARN },
                    -- prefix = "icons", -- TODO: nvim 0.10.0
                },
                float = { header = false, source = 'always' },
                virtual_text = false,
                -- virtual_text = {
                --     -- spacing = 4,
                --     -- prefix = '■', -- ■ 
                -- },
                update_in_insert = true,
                severity_sort = true,
            }

            function lsp.show_lightbulb()
                require('nvim-lightbulb').update_lightbulb {
                    sign = { enabled = false, priority = 99 },
                    virtual_text = {
                        enabled = true,
                        text = '',
                        hl_mode = 'combine',
                    },
                }
            end

            vim.api.nvim_create_user_command('Format', function()
                vim.lsp.buf.format { async = false }
            end, {})

            -- Handle formatting in a smarter way
            -- If the buffer has been edited before formatting has completed, do not try to
            -- apply the changes, original by Lukas Reineke
            vim.lsp.handlers['textDocument/formatting'] = function(
                err,
                result,
                ctx
            )
                local client = vim.lsp.get_client_by_id(ctx.client_id)
                if not client then
                    return
                end
                if err then
                    local err_msg = type(err) == 'string' and err or err.message
                    vim.notify(
                        ('%s formatting error: %s'):format(client.name, err_msg),
                        vim.log.levels.ERROR
                    )
                    return
                end

                if result == nil then
                    -- vim.notify('no formatting changes', vim.lsp.log_levels.DEBUG)
                    return
                end

                local bufnr = ctx.bufnr
                -- abort if the buffer has been modified before the formatting has finished
                if
                    not vim.api.nvim_buf_is_loaded(bufnr)
                    or vim.api.nvim_get_option_value(
                        'modified',
                        { buf = bufnr }
                    )
                then
                    return
                end

                -- local pos = vim.api.nvim_win_get_cursor(0)
                vim.lsp.util.apply_text_edits(
                    result,
                    bufnr,
                    client.offset_encoding or 'utf-16'
                )
                -- pcall(vim.api.nvim_win_set_cursor, 0, pos)
                vim.api.nvim_buf_call(bufnr, function()
                    vim.cmd 'silent noautocmd update'
                end)
                vim.notify(
                    ('%s formatting success'):format(client.name),
                    vim.lsp.log_levels.DEBUG
                )

                -- Trigger post-formatting autocommand which can be used to refresh gitsigns
                -- vim.api.nvim_exec_autocmds(
                --     'User FormatterPost',
                --     { modeline = false }
                -- )
            end

            -- show diagnostics for current line as virtual text
            -- from https://github.com/kristijanhusak/neovim-config/blob/5977ad2c5dd9bfbb7f24b169fef01828717ea9dc/nvim/lua/partials/lsp.lua#L169
            local diagnostic_ns = vim.api.nvim_create_namespace 'diagnostics'
            function lsp.show_diagnostics()
                vim.schedule(function()
                    local line = vim.api.nvim_win_get_cursor(0)[1] - 1
                    local bufnr = vim.api.nvim_get_current_buf()
                    local diagnostics = vim.diagnostic.get(bufnr, {
                        lnum = line,
                        severity = { min = vim.diagnostic.severity.INFO },
                    })
                    vim.diagnostic.show(
                        diagnostic_ns,
                        bufnr,
                        diagnostics,
                        { virtual_text = true }
                    )
                end)
            end

            function lsp.refresh_diagnostics()
                vim.diagnostic.setloclist { open = false }
                lsp.show_diagnostics()
                if vim.tbl_isempty(vim.fn.getloclist(0)) then
                    vim.cmd [[lclose]]
                end
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP options',
                callback = function(args)
                    local bufnr = args.buf
                    vim.api.nvim_set_option_value(
                        'formatexpr',
                        'v:lua.vim.lsp.formatexpr',
                        { buf = bufnr }
                    )
                    vim.api.nvim_set_option_value(
                        'tagfunc',
                        'v:lua.vim.lsp.tagfunc',
                        { buf = bufnr }
                    )
                end,
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP keymaps',
                callback = function(args)
                    local bufnr = args.buf
                    local function map(mode, lhs, rhs)
                        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr })
                    end

                    map('n', 'gD', vim.lsp.buf.declaration)
                    map('n', 'gd', vim.lsp.buf.definition)
                    map('n', 'K', vim.lsp.buf.hover)
                    map('n', 'gi', vim.lsp.buf.implementation)
                    map({ 'n', 'i' }, '<C-s>', vim.lsp.buf.signature_help)
                    map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder)
                    map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder)
                    map('n', '<leader>wl', function()
                        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    end)
                    map('n', '<leader>D', vim.lsp.buf.type_definition)
                    map('n', '<leader>r', function()
                        require('conf.nui_lsp').lsp_rename()
                    end)
                    map('n', 'gr', function()
                        require('trouble').open { mode = 'lsp_references' }
                    end)
                    map('n', 'gR', vim.lsp.buf.references)
                    map('n', '<leader>li', vim.lsp.buf.incoming_calls)
                    map('n', '<leader>lo', vim.lsp.buf.outgoing_calls)
                    map('n', '<leader>lt', vim.lsp.buf.document_symbol)
                    map('n', '<leader>d', function()
                        vim.diagnostic.open_float {
                            {
                                scope = 'line',
                                border = 'single',
                                focusable = false,
                                severity_sort = true,
                            },
                        }
                    end)
                    map('n', '[d', function()
                        vim.diagnostic.goto_prev { float = false }
                    end)
                    map('n', ']d', function()
                        vim.diagnostic.goto_next { float = false }
                    end)
                    map('n', '[e', function()
                        vim.diagnostic.goto_prev {
                            enable_popup = false,
                            severity = { min = vim.diagnostic.severity.WARN },
                        }
                    end)
                    map('n', ']e', function()
                        vim.diagnostic.goto_next {
                            enable_popup = false,
                            severity = { min = vim.diagnostic.severity.WARN },
                        }
                    end)
                    map('n', '<leader>q', vim.diagnostic.setloclist)
                    map('n', '<leader>ls', vim.lsp.buf.document_symbol)
                    map('n', '<leader>lS', vim.lsp.buf.workspace_symbol)
                    vim.opt.shortmess:append 'c'
                end,
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP highlight',
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if
                        client
                        and client.supports_method 'textDocument/documentHighlight'
                    then
                        local augroup_lsp_highlight = 'lsp_highlight'
                        vim.api.nvim_create_augroup(
                            augroup_lsp_highlight,
                            { clear = false }
                        )
                        vim.api.nvim_create_autocmd(
                            { 'CursorHold', 'CursorHoldI' },
                            {
                                group = augroup_lsp_highlight,
                                buffer = bufnr,
                                callback = vim.lsp.buf.document_highlight,
                            }
                        )
                        vim.api.nvim_create_autocmd('CursorMoved', {
                            group = augroup_lsp_highlight,
                            buffer = bufnr,
                            callback = vim.lsp.buf.clear_references,
                        })
                    end
                end,
            })

            local servers_autoformat_disabled = {
                'pylance',
                'ruff_lsp', -- FIXME: chain formatting with multiple LSPs to avoid corruption
                'eslint',
                'tsserver',
                'jsonls',
                'lua_ls',
            }
            local augroup_lsp_format =
                vim.api.nvim_create_augroup('lsp_format', {})
            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP format',
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if not client then
                        return
                    end

                    if
                        vim.tbl_contains(
                            servers_autoformat_disabled,
                            client.name
                        )
                    then
                        return
                    end

                    local existing_autocommands = vim.api.nvim_get_autocmds {
                        group = augroup_lsp_format,
                        buffer = bufnr,
                    }
                    for _, existing_autocommand in ipairs(existing_autocommands) do
                        if
                            existing_autocommand.desc:match(
                                client.name:gsub('%-', '%%-') -- convert string to pattern
                            )
                        then
                            vim.api.nvim_clear_autocmds {
                                group = augroup_lsp_format,
                                buffer = bufnr,
                            }
                            break
                        end
                    end

                    vim.api.nvim_create_autocmd('BufWritePost', {
                        group = augroup_lsp_format,
                        buffer = bufnr,
                        desc = ('%s format'):format(client.name),
                        callback = function()
                            if
                                client.supports_method 'textDocument/formatting'
                            then
                                vim.lsp.buf.format {
                                    async = true,
                                    bufnr = bufnr,
                                    --[[ filter = function(server)
                                -- return server.name == 'null-ls'
                                return not vim.tbl_contains(
                                    servers_autoformat_disabled,
                                    server.name
                                )
                            end, ]]
                                }
                            end
                        end,
                    })
                end,
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP code actions',
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if
                        client
                        and client.supports_method 'textDocument/codeAction'
                    then
                        vim.api.nvim_create_autocmd(
                            { 'CursorHold', 'CursorHoldI' },
                            {
                                buffer = bufnr,
                                callback = function()
                                    lsp.show_lightbulb()
                                end,
                            }
                        )
                        vim.keymap.set(
                            { 'n', 'v' },
                            '<leader>a',
                            vim.lsp.buf.code_action,
                            { buffer = bufnr }
                        )
                    end
                end,
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP diagnostics',
                callback = function(args)
                    local bufnr = args.buf
                    vim.api.nvim_create_autocmd(
                        { 'CursorHold', 'CursorHoldI' },
                        {
                            buffer = bufnr,
                            callback = lsp.show_diagnostics,
                        }
                    )
                    vim.api.nvim_create_autocmd('DiagnosticChanged', {
                        buffer = bufnr,
                        callback = lsp.refresh_diagnostics,
                    })
                end,
            })

            --[[ vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP signature help',
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client.supports_method 'textDocument/signatureHelp' then
                        vim.api.nvim_create_autocmd('CursorHoldI', {
                            buffer = bufnr,
                            callback = function()
                                vim.defer_fn(vim.lsp.buf.signature_help, 200)
                            end,
                        })
                    end
                end,
            }) ]]

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP notify',
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client then
                        vim.notify(
                            ('%s attached to buffer %s'):format(
                                client.name,
                                args.buf
                            ),
                            vim.log.levels.DEBUG
                        )
                    end
                end,
            })
        end,
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            { 'folke/neodev.nvim', config = true },
            {
                'williamboman/mason.nvim',
                cmd = 'Mason',
                opts = {
                    registries = {
                        'github:mason-org/mason-registry',
                        'lua:plugins.lsp.custom',
                    },
                },
                config = true,
            },
            {
                'williamboman/mason-lspconfig.nvim',
                opts = {
                    ensure_installed = {
                        'lua_ls',
                        'ruff_lsp',
                        'pylyzer',
                        'rust_analyzer',
                        'dockerls',
                        'docker_compose_language_service',
                        'yamlls',
                        'jsonls',
                        'html',
                        'cssls',
                        'gopls',
                        'clangd',
                        'texlab',
                        'vtsls',
                        'denols',
                        'tsserver',
                        'eslint',
                        'vale_ls',
                        'terraformls',
                        'helm_ls',
                        'bashls',
                        'pylance',
                    },
                    handlers = {
                        function(server_name)
                            -- vim.notify(
                            --     'Mason LSP setup ' .. server_name,
                            --     vim.log.levels.DEBUG
                            -- )
                            require('lspconfig')[server_name].setup {}
                        end,
                        ['yamlls'] = function()
                            require('lspconfig').yamlls.setup {
                                single_file_support = false,
                                root_dir = function(filename)
                                    if
                                        filename:match 'pipeline[_%w]*.yaml'
                                        or filename:match 'config.yaml'
                                        or filename:match 'defaults[_%w]*.yaml'
                                    then
                                        return nil -- handled by KPOps LSP
                                    end
                                    return require('lspconfig.util').find_git_ancestor(
                                        filename
                                    ) or vim.loop.cwd()
                                end,
                                settings = {
                                    yaml = {
                                        editor = { formatOnType = true },
                                        schemas = {
                                            -- GitHub CI workflows
                                            ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
                                            -- Helm charts
                                            ['https://json.schemastore.org/chart.json'] = '/templates/*',
                                        },
                                        customTags = {
                                            -- GitLab CI
                                            '!reference sequence',
                                            '!reference scalar',
                                            -- mkdocs
                                            'tag:yaml.org,2002:python/name:material.extensions.emoji.twemoji',
                                            'tag:yaml.org,2002:python/name:material.extensions.emoji.to_svg',
                                            'tag:yaml.org,2002:python/name:pymdownx.superfences.fence_code_format',
                                        },
                                    },
                                },
                            }
                        end,
                        ['ruff_lsp'] = function()
                            require('lspconfig').ruff_lsp.setup {
                                handlers = {
                                    ['textDocument/hover'] = function() end, -- disable
                                },
                                commands = {
                                    RuffAutofix = {
                                        function()
                                            vim.lsp.buf.execute_command {
                                                command = 'ruff.applyAutofix',
                                                arguments = {
                                                    {
                                                        uri = vim.uri_from_bufnr(
                                                            0
                                                        ),
                                                    },
                                                },
                                            }
                                        end,
                                        description = 'Ruff: Fix all auto-fixable problems',
                                    },
                                    RuffOrganizeImports = {
                                        function()
                                            vim.lsp.buf.execute_command {
                                                command = 'ruff.applyOrganizeImports',
                                                arguments = {
                                                    {
                                                        uri = vim.uri_from_bufnr(
                                                            0
                                                        ),
                                                    },
                                                },
                                            }
                                        end,
                                        description = 'Ruff: Format imports',
                                    },
                                },
                            }
                        end,
                        ['pylyzer'] = function() end, -- disable
                        ['rust_analyzer'] = function() end, -- use rustaceanvim instead
                        ['dockerls'] = function()
                            require('lspconfig').dockerls.setup {
                                settings = {
                                    docker = {
                                        languageserver = {
                                            formatter = {
                                                ignoreMultilineInstructions = true,
                                            },
                                        },
                                    },
                                },
                            }
                        end,
                        ['jsonls'] = function()
                            require('lspconfig').jsonls.setup {
                                filetypes = { 'json', 'jsonc' },
                                settings = {
                                    json = {
                                        schemas = {
                                            {
                                                fileMatch = { 'package.json' },
                                                url = 'https://json.schemastore.org/package.json',
                                            },
                                            {
                                                fileMatch = { 'tsconfig*.json' },
                                                url = 'https://json.schemastore.org/tsconfig.json',
                                            },
                                            {
                                                fileMatch = {
                                                    '.prettierrc',
                                                    '.prettierrc.json',
                                                    'prettier.config.json',
                                                },
                                                url = 'https://json.schemastore.org/prettierrc.json',
                                            },
                                            {
                                                fileMatch = {
                                                    '.eslintrc',
                                                    '.eslintrc.json',
                                                },
                                                url = 'https://json.schemastore.org/eslintrc.json',
                                            },
                                            {
                                                fileMatch = {
                                                    '.stylelintrc',
                                                    '.stylelintrc.json',
                                                    'stylelint.config.json',
                                                },
                                                url = 'http://json.schemastore.org/stylelintrc.json',
                                            },
                                        },
                                    },
                                },
                            }
                        end,
                        ['html'] = function()
                            require('lspconfig').html.setup {
                                settings = {
                                    html = {
                                        format = {
                                            templating = true,
                                            wrapLineLength = 120,
                                            wrapAttributes = 'auto',
                                        },
                                        hover = {
                                            documentation = true,
                                            references = true,
                                        },
                                    },
                                },
                            }
                        end,
                        ['tsserver'] = function()
                            require('lspconfig').tsserver.setup {
                                autostart = false,
                                root_dir = require('lspconfig.util').root_pattern 'package.json',
                                commands = {
                                    OrganizeImports = {
                                        function()
                                            local params = {
                                                command = '_typescript.organizeImports',
                                                arguments = {
                                                    vim.api.nvim_buf_get_name(
                                                        0
                                                    ),
                                                },
                                                title = '',
                                            }
                                            vim.lsp.buf.execute_command(params)
                                        end,
                                    },
                                },
                            }
                        end,
                        ['lua_ls'] = function()
                            require('lspconfig').lua_ls.setup {
                                settings = {
                                    Lua = {
                                        completion = {
                                            callSnippet = 'Replace',
                                        },
                                        workspace = { checkThirdParty = false },
                                        telemetry = { enable = false },
                                        diagnostics = {
                                            unusedLocalExclude = { '_*' },
                                        },
                                        format = { enable = false },
                                        hint = {
                                            enable = true,
                                            arrayIndex = 'Disable',
                                        },
                                    },
                                },
                            }
                        end,
                        ['denols'] = function()
                            require('lspconfig').denols.setup {
                                autostart = false,
                                root_dir = require('lspconfig.util').root_pattern(
                                    'deno.json',
                                    'deno.jsonc'
                                ),
                                filetypes = {
                                    'javascript',
                                    'javascriptreact',
                                    'javascript.jsx',
                                    'typescript',
                                    'typescriptreact',
                                    'typescript.tsx',
                                    'yaml',
                                    'json',
                                    'markdown',
                                    'html',
                                    'css',
                                },
                                init_options = {
                                    enable = true,
                                    lint = true,
                                    unstable = true,
                                    importMap = './import_map.json',
                                },
                                single_file_support = false,
                            }
                        end,
                        ['texlab'] = function()
                            require('lspconfig').texlab.setup {
                                settings = {
                                    texlab = {
                                        auxDirectory = '.',
                                        bibtexFormatter = 'texlab',
                                        build = {
                                            args = {
                                                '-pdflua',
                                                '-shell-escape',
                                                '-interaction=nonstopmode',
                                                '-synctex=1',
                                                '-pv',
                                                '%f',
                                            },
                                            executable = 'latexmk',
                                            forwardSearchAfter = false,
                                            onSave = false,
                                        },
                                        chktex = {
                                            onEdit = false,
                                            onOpenAndSave = false,
                                        },
                                        diagnosticsDelay = 300,
                                        formatterLineLength = 80,
                                        forwardSearch = {
                                            args = {},
                                        },
                                        latexFormatter = 'latexindent',
                                        latexindent = {
                                            modifyLineBreaks = false,
                                        },
                                    },
                                },
                            }
                        end,
                    },
                },
            },
        },
    },
    {
        'disrupted/pylance.nvim',
        -- build = 'bash ./install.sh',
        ft = 'python',
        -- config = true,
    },
    {
        dir = '~/bakdata/kpops.nvim',
        -- 'disrupted/kpops.nvim',
        ft = 'yaml',
        opts = {
            settings = {
                kpops = {
                    generate_schema = true,
                },
            },
        },
        config = true,
    },
    { 'kosayoda/nvim-lightbulb', lazy = true },
    {
        'zbirenbaum/neodim',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            alpha = 0.70,
            blend_color = '#000000',
            update_in_insert = {
                enable = false,
                delay = 100,
            },
            hide = {
                virtual_text = false,
                signs = false,
                underline = true,
            },
        },
        config = function(_, opts)
            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP dim unused',
                callback = function()
                    require('neodim').setup(opts)
                end,
            })
        end,
    },
    {
        'lvimuser/lsp-inlayhints.nvim',
        branch = 'anticonceal',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP inlay hints',
                callback = function(args)
                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if
                        client
                        and client.supports_method 'textDocument/inlayHint'
                        and pcall(require, 'vim.lsp.inlay_hint') -- NOTE: check that API exists
                    then
                        vim.notify(
                            'register inlay hints',
                            vim.lsp.log_levels.DEBUG
                        )
                        -- local lsp_inlayhints = require 'lsp-inlayhints'
                        -- lsp_inlayhints.setup {
                        --     enabled_at_startup = true,
                        --     debug_mode = false,
                        -- }
                        -- lsp_inlayhints.on_attach(client, bufnr, false)
                        -- TODO: native inlay hints, also when cycling between two bufs making changes to function parameter hints
                        vim.api.nvim_create_autocmd({
                            'BufWritePost',
                            'BufEnter',
                            'InsertLeave',
                            'FocusGained',
                            'CursorHold',
                        }, {
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.inlay_hint.enable(bufnr, true)
                            end,
                        })
                        vim.api.nvim_create_autocmd('InsertEnter', {
                            callback = function()
                                vim.lsp.inlay_hint.enable(bufnr, false)
                            end,
                        })
                        -- initial request
                        vim.lsp.inlay_hint.enable(bufnr, true)
                    end
                end,
            })
        end,
    },
    {
        'nvimtools/none-ls.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = function()
            local null_ls = require 'null-ls'

            -- custom sources
            local h = require 'null-ls.helpers'

            local function dprint_config()
                for _, dprint_config in ipairs { 'dprint.jsonc', 'dprint.json' } do
                    if vim.loop.fs_stat(dprint_config) then
                        vim.notify('found local ' .. dprint_config)
                        return dprint_config
                    end
                end
                vim.notify 'falling back to global dprint config'
                return vim.fn.expand '~/.config/dprint.jsonc'
            end

            local dprint = {
                name = 'dprint',
                method = null_ls.methods.FORMATTING,
                filetypes = {
                    'json',
                    'jsonc',
                    'markdown',
                    'javascript',
                    'javascriptreact',
                    'typescript',
                    'typescriptreact',
                    'toml',
                    'dockerfile',
                    'css',
                    'html',
                    'htmldjango',
                },
                generator = h.formatter_factory {
                    command = 'dprint',
                    -- condition = function(utils)
                    --     return utils.root_has_file 'dprint.jsonc'
                    -- end,
                    args = function()
                        return {
                            'fmt',
                            '--config',
                            dprint_config(),
                            '--stdin',
                            '$FILENAME', -- full path, necessary to check against include/exclude rules
                        }
                    end,
                    to_stdin = true,
                },
            }

            local ruff_fix = {
                name = 'ruff',
                meta = {
                    url = 'https://github.com/astral-sh/ruff',
                    description = 'An extremely fast Python linter and formatter, written in Rust.',
                },
                method = null_ls.methods.FORMATTING,
                filetypes = { 'python' },
                generator = h.formatter_factory {
                    command = 'ruff',
                    args = {
                        '--fix',
                        '-e',
                        '-n',
                        '--stdin-filename',
                        '$FILENAME',
                        '-',
                    },
                    to_stdin = true,
                },
            }

            local ruff_format = {
                name = 'ruff format',
                meta = {
                    url = 'https://github.com/astral-sh/ruff',
                    description = 'An extremely fast Python linter and formatter, written in Rust.',
                },
                method = null_ls.methods.FORMATTING,
                filetypes = { 'python' },
                generator = h.formatter_factory {
                    command = 'ruff',
                    args = {
                        'format',
                        '--silent',
                        '--respect-gitignore',
                        '--force-exclude',
                        '--stdin-filename',
                        '$FILENAME',
                        '-',
                    },
                    to_stdin = true,
                },
            }

            local sources = {
                null_ls.builtins.formatting.stylua.with {
                    condition = function(utils)
                        return utils.root_has_file 'stylua.toml'
                            or utils.root_has_file '.stylua.toml'
                    end,
                },
                -- null_ls.builtins.formatting.isortd,
                -- null_ls.builtins.formatting.blackd.with {
                --     config = {
                --         fast = true,
                --         preview = false,
                --     },
                -- },
                ruff_fix,
                ruff_format,
                -- null_ls.builtins.formatting.dprint,
                dprint,
                null_ls.builtins.formatting.prettier.with {
                    filetypes = {
                        'yaml',
                        'graphql',
                    },
                    -- condition = function(utils)
                    --     return not utils.root_has_file 'dprint.jsonc'
                    -- end,
                },
                null_ls.builtins.formatting.uncrustify.with {
                    condition = function(utils)
                        return utils.root_has_file 'uncrustify.cfg'
                    end,
                    extra_args = function()
                        return {
                            -- for neovim/neovim repo
                            '-c',
                            require('lspconfig.util').path.join(
                                vim.loop.cwd(),
                                'uncrustify.cfg'
                            ),
                        }
                    end,
                },
                null_ls.builtins.formatting.shfmt.with {
                    extra_args = { '-i', '4', '-ci' },
                },
                -- null_ls.builtins.formatting.trim_whitespace,
                -- null_ls.builtins.formatting.trim_newlines,
                -- null_ls.builtins.diagnostics.shellcheck,
                null_ls.builtins.diagnostics.actionlint.with {
                    -- based on https://github.com/jose-elias-alvarez/null-ls.nvim/pull/804
                    runtime_condition = function()
                        local path = vim.api.nvim_buf_get_name(
                            vim.api.nvim_get_current_buf()
                        )
                        return path:match 'github/workflows/' ~= nil
                    end,
                },
                -- null_ls.builtins.code_actions.refactoring,
                null_ls.builtins.code_actions.gitrebase,
            }

            return {
                sources = sources,
                debug = false,
                -- Fallback to .zshrc as a project root to enable LSP on loose files
                root_dir = function(fname)
                    return require('lspconfig.util').root_pattern(
                        'tsconfig.json',
                        'pyproject.toml',
                        'stylua.toml',
                        '.stylua.toml',
                        'dprint.jsonc',
                        'dprint.json'
                    )(fname) or require('lspconfig.util').root_pattern(
                        '.eslintrc.js',
                        '.git'
                    )(fname) or require('lspconfig.util').root_pattern(
                        'package.json',
                        '.git/',
                        '.zshrc'
                    )(fname)
                end,
            }
        end,
    },
    { 'mrcjkb/rustaceanvim', ft = 'rust' },
    {
        'folke/trouble.nvim',
        cmd = 'Trouble',
        keys = {
            {
                '<leader>xx',
                function()
                    require('trouble').toggle()
                end,
            },
            {
                '<leader>xw',
                function()
                    require('trouble').toggle { mode = 'workspace_diagnostics' }
                end,
            },
            {
                '<leader>xb',
                function()
                    require('trouble').toggle { mode = 'document_diagnostics' }
                end,
            },
            {
                '<leader>xq',
                function()
                    require('trouble').toggle { mode = 'quickfix' }
                end,
            },
        },
        opts = {
            fold_open = '', -- ▾
            fold_closed = '', -- ▸
            indent_lines = false,
            padding = false,
            signs = {
                error = '',
                warning = '',
                hint = '',
                information = '',
                other = '', -- 
            },
            action_keys = { jump = { '<cr>' }, toggle_fold = { '<tab>' } },
        },
        config = function(_, opts)
            require('trouble').setup(opts)
            vim.api.nvim_set_hl(0, 'TroubleText', { link = 'CursorLineNr' })

            vim.api.nvim_create_autocmd('QuitPre', {
                callback = function()
                    local invalid_wins = {}
                    local wins = vim.api.nvim_list_wins()
                    for _, w in ipairs(wins) do
                        local bufname = vim.api.nvim_buf_get_name(
                            vim.api.nvim_win_get_buf(w)
                        )
                        if
                            bufname:match 'Trouble' ~= nil
                            or vim.api.nvim_win_get_config(w).relative ~= '' -- floating window
                        then
                            table.insert(invalid_wins, w)
                        end
                    end
                    if #invalid_wins == #wins - 1 then
                        -- Should quit, so we close all invalid windows.
                        for _, w in ipairs(invalid_wins) do
                            vim.api.nvim_win_close(w, true)
                        end
                    end
                end,
                desc = 'Close Trouble if last window',
            })
        end,
    },
    {
        'simrat39/symbols-outline.nvim',
        cmd = 'SymbolsOutline',
        keys = { { '|', '<cmd>SymbolsOutline<cr>' } },
        opts = {
            show_guides = false,
            auto_preview = false,
            preview_bg_highlight = 'Normal',
            symbols = {
                File = { icon = '', hl = 'TSURI' },
                Module = { icon = '', hl = 'TSNamespace' },
                Namespace = { icon = '', hl = 'TSNamespace' },
                Package = { icon = '', hl = 'TSNamespace' },
                Class = { icon = 'ﴯ', hl = 'TSType' },
                Method = { icon = '', hl = 'TSMethod' },
                Property = { icon = 'ﰠ', hl = 'TSMethod' },
                Field = { icon = 'ﰠ', hl = 'TSField' },
                Constructor = { icon = '', hl = 'TSConstructor' },
                Enum = { icon = '', hl = 'TSType' },
                Interface = { icon = '', hl = 'TSType' },
                Function = { icon = '', hl = 'TSFunction' },
                Variable = { icon = '', hl = 'TSConstant' },
                Constant = { icon = '', hl = 'TSConstant' },
                String = { icon = '', hl = 'TSString' },
                Number = { icon = '', hl = 'TSNumber' },
                Boolean = { icon = '⊨', hl = 'TSBoolean' },
                Array = { icon = '', hl = 'TSConstant' },
                Object = { icon = '⦿', hl = 'TSType' },
                Key = { icon = '', hl = 'TSType' },
                Null = { icon = 'NULL', hl = 'TSType' },
                EnumMember = { icon = '', hl = 'TSField' },
                Struct = { icon = 'פּ', hl = 'TSType' },
                Event = { icon = '', hl = 'TSType' },
                Operator = { icon = '', hl = 'TSOperator' },
                TypeParameter = { icon = '', hl = 'TSParameter' },
            },
        },
    },
}
