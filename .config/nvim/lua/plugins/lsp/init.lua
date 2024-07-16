local au = vim.api.nvim_create_augroup('LspAttach', { clear = true })
return {
    {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        opts = {
            ensure_installed = {},
            registries = {
                'github:mason-org/mason-registry',
                'lua:plugins.lsp.custom',
            },
        },
        config = function(_, opts)
            require('mason').setup(opts)

            local registry = require 'mason-registry'
            registry:on('package:install:success', function()
                vim.defer_fn(function()
                    -- trigger FileType event to possibly load this newly installed LSP server
                    require('lazy.core.handler.event').trigger {
                        event = 'FileType',
                        buf = vim.api.nvim_get_current_buf(),
                    }
                end, 100)
            end)

            local function ensure_installed()
                for _, tool in ipairs(opts.ensure_installed) do
                    local package = registry.get_package(tool)
                    if not package:is_installed() then
                        package:install()
                    end
                end
            end

            if registry.refresh then
                registry.refresh(ensure_installed)
            else
                ensure_installed()
            end
        end,
    },
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        init = function()
            -- client log level
            vim.lsp.set_log_level(vim.lsp.log_levels.INFO)

            vim.api.nvim_create_user_command('LspFormat', function()
                vim.lsp.buf.format { async = false }
            end, {})

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP tagfunc',
                callback = function(args)
                    local bufnr = args.buf
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
                        vim.api.nvim_create_autocmd({
                            'BufWritePost',
                            'BufEnter',
                            'InsertLeave',
                            'FocusGained',
                            'CursorHold',
                        }, {
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.inlay_hint.enable(
                                    true,
                                    { bufnr = bufnr }
                                )
                            end,
                        })
                        vim.api.nvim_create_autocmd('InsertEnter', {
                            callback = function()
                                vim.lsp.inlay_hint.enable(
                                    false,
                                    { bufnr = bufnr }
                                )
                            end,
                        })
                        -- initial request
                        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                    end
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
                        vim.keymap.set(
                            { 'n', 'v' },
                            '<leader>a',
                            vim.lsp.buf.code_action,
                            { buffer = bufnr }
                        )
                    end
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
            {
                'folke/neoconf.nvim',
                cmd = 'Neoconf',
                config = false,
                dependencies = { 'nvim-lspconfig' },
            },
            { 'folke/neodev.nvim', opts = {} },
            'hrsh7th/cmp-nvim-lsp',
            'mason.nvim',
            {
                'williamboman/mason-lspconfig.nvim',
                opts = {
                    ensure_installed = {
                        'lua_ls',
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
                        'gitlab_ci_ls',
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
                                single_file_support = true,
                                filetypes = {
                                    'yaml',
                                    'yaml.gha',
                                },
                                root_dir = function(filename)
                                    return require('lspconfig.util').find_git_ancestor(
                                        filename
                                    ) or vim.uv.cwd()
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
                                            -- mkdocs
                                            'tag:yaml.org,2002:python/name:material.extensions.emoji.twemoji',
                                            'tag:yaml.org,2002:python/name:material.extensions.emoji.to_svg',
                                            'tag:yaml.org,2002:python/name:pymdownx.superfences.fence_code_format',
                                        },
                                    },
                                },
                            }
                            require('lspconfig').yamlls.setup {
                                name = 'yamlls GitLab',
                                filetypes = { 'yaml.gitlab' },
                                settings = {
                                    yaml = {
                                        customTags = {
                                            '!reference sequence',
                                            '!reference scalar',
                                        },
                                    },
                                },
                            }
                        end,
                        ['pylyzer'] = function() end, -- disable
                        ['vale_ls'] = function() end, -- disable
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
            {
                'antosha417/nvim-lsp-file-operations',
                dependencies = {
                    'nvim-lua/plenary.nvim',
                    'nvim-tree/nvim-tree.lua',
                },
                opts = {},
            },
        },
    },
    {
        'disrupted/pylance.nvim',
        ft = 'python',
    },
    {
        -- 'disrupted/kpops.nvim',
        dir = '~/bakdata/kpops.nvim',
        ft = 'yaml.kpops',
        opts = {},
    },
    {
        'neovim-plugin/lightbulb.nvim',
        event = 'LspAttach',
        opts = {
                    sign = { enabled = false, priority = 99 },
                    virtual_text = {
                        enabled = true,
                        text = '',
                        hl_mode = 'combine',
                    },
        },
    },
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
        'stevearc/conform.nvim',
        event = { 'BufWritePre' },
        dependencies = {
            {
                'williamboman/mason.nvim',
                opts = function(_, opts)
                    opts.ensure_installed = opts.ensure_installed or {}
                    vim.list_extend(opts.ensure_installed, {
                        'stylua',
                        'ruff',
                        'dprint',
                        'isort',
                        'black',
                        'prettierd',
                        'shfmt',
                    })
                end,
            },
        },
        opts = {
            formatters_by_ft = {
                lua = { 'stylua' },
                python = function(bufnr)
                    if
                        require('conform').get_formatter_info(
                            'ruff_format',
                            bufnr
                        ).available
                    then
                        return { 'ruff_fix', 'ruff_format' }
                    else
                        return { 'isort', 'black' }
                    end
                end,
                json = { 'dprint' },
                jsonc = { 'dprint' },
                markdown = { 'dprint', 'injected' },
                javascript = { 'dprint' },
                javascriptreact = { 'dprint' },
                typescript = { 'dprint' },
                typescriptreact = { 'dprint' },
                toml = { 'dprint' },
                dockerfile = { 'dprint' },
                css = { 'dprint' },
                html = { 'dprint' },
                htmldjango = { 'dprint' },
                yaml = { 'dprint' },
                graphql = { { 'prettierd', 'prettier' } },
                sh = { 'shfmt' },
                http = {
                    'injected',
                    -- 'trim_newlines', -- FIXME: breaks injected
                    'trim_whitespace',
                },
                ['_'] = { 'trim_newlines', 'trim_whitespace' },
            },
            format_on_save = function(bufnr)
                -- Disable with a global or buffer-local variable
                if
                    vim.g.disable_autoformat
                    or vim.b[bufnr].disable_autoformat
                then
                    return
                end
                return {
                    timeout_ms = 5000, -- HACK: high because dprint needs to download WASM plugins on first run
                    lsp_fallback = true,
                }
            end,
            log_level = vim.log.levels.TRACE,
        },
        init = function()
            vim.api.nvim_create_user_command('Format', function()
                require('conform').format()
            end, { desc = 'Format buffer using conform' })

            vim.api.nvim_create_user_command('FormatDisable', function(args)
                if args.bang then
                    -- FormatDisable! will disable formatting just for this buffer
                    ---@diagnostic disable-next-line: inject-field
                    vim.b.disable_autoformat = true
                else
                    vim.g.disable_autoformat = true
                end
            end, {
                desc = 'Disable autoformat-on-save',
                bang = true,
            })
            vim.api.nvim_create_user_command('FormatEnable', function()
                ---@diagnostic disable-next-line: inject-field
                vim.b.disable_autoformat = false
                vim.g.disable_autoformat = false
            end, {
                desc = 'Re-enable autoformat-on-save',
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = au,
                desc = 'LSP formatexpr',
                callback = function(args)
                    local bufnr = args.buf
                    vim.api.nvim_set_option_value(
                        'formatexpr',
                        'v:lua.require\'conform\'.formatexpr()',
                        { buf = bufnr }
                    )
                end,
            })
        end,
        config = function(_, opts)
            local conform = require 'conform'
            conform.setup(opts)

            conform.formatters.stylua = {
                require_cwd = true,
            }
            -- conform.formatters.ruff_fix = {
            --     prepend_args = { '--respect-gitignore' },
            -- }
            -- conform.formatters.ruff_format = {
            --     prepend_args = { '--silent', '--respect-gitignore' },
            -- }
            conform.formatters.shfmt = {
                prepend_args = { '-i', '4', '-ci' },
            }
            conform.formatters.dprint = {
                prepend_args = function(self, ctx)
                    if not self:cwd(ctx) then
                        vim.notify 'falling back to global dprint config'
                        return {
                            '--config',
                            vim.fn.expand '~/.config/dprint.jsonc',
                        }
                    end
                end,
            }
            conform.formatters.dprint_injected = vim.tbl_deep_extend(
                'force',
                require 'conform.formatters.dprint',
                conform.formatters.dprint,
                {
                    args = function(self, ctx)
                        local extension = vim.fn.fnamemodify(ctx.filename, ':e')
                        local ret = vim.list_extend(
                            { 'fmt', '--stdin', extension },
                            self:prepend_args(ctx)
                        )
                        return ret
                    end,
                }
            )
            conform.formatters.injected = {
                options = {
                    ignore_errors = false,
                    lang_to_formatters = {
                        json = { 'dprint_injected' },
                        python = { 'black' }, -- FIXME: ruff_format deletes content
                    },
                },
            }

            -- TODO: custom formatters
            conform.formatters.blackd = {
                command = 'blackd-client',
            }
        end,
    },
    {
        'joechrisellis/lsp-format-modifications.nvim',
        lazy = true,
        dependencies = { 'nvim-lua/plenary.nvim' },
        init = function()
            vim.api.nvim_create_user_command('FormatModified', function()
                local bufnr = vim.api.nvim_get_current_buf()
                local clients = vim.lsp.get_clients {
                    bufnr = bufnr,
                    method = require('vim.lsp.protocol').Methods.textDocument_rangeFormatting,
                }

                if #clients == 0 then
                    vim.notify '[LSP] Format request failed, no matching language servers.'
                end

                for _, client in pairs(clients) do
                    require('lsp-format-modifications').format_modifications(
                        client,
                        bufnr
                    )
                end
            end, {})
        end,
    },
    {
        'mfussenegger/nvim-lint',
        ft = { 'yaml.gha' },
        dependencies = {
            {
                'williamboman/mason.nvim',
                opts = function(_, opts)
                    opts.ensure_installed = opts.ensure_installed or {}
                    vim.list_extend(opts.ensure_installed, { 'actionlint' })
                end,
            },
        },
        opts = {
            events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
            linters_by_ft = {
                ['yaml.gha'] = { 'actionlint' },
            },
            -- from LazyVim: https://github.com/LazyVim/LazyVim/blob/bb36f71b77d8e15788a5b62c82a1c9ec7b209e49/lua/lazyvim/plugins/linting.lua#L16
            -- easily override linter options or add custom linters
            ---@type table<string,table>
            linters = {
                -- Example of using selene only when a selene.toml file is present
                -- selene = {
                --   -- dynamically enable/disable linters based on the context.
                --   condition = function(ctx)
                --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
                --   end,
                -- },
            },
        },
        config = function(_, opts)
            local lint = require 'lint'
            for name, linter in pairs(opts.linters) do
                if
                    type(linter) == 'table'
                    and type(lint.linters[name]) == 'table'
                then
                    lint.linters[name] =
                        vim.tbl_deep_extend('force', lint.linters[name], linter)
                else
                    lint.linters[name] = linter
                end
            end
            lint.linters_by_ft = opts.linters_by_ft

            local M = {}
            function M.debounce(ms, fn)
                local timer = assert(vim.uv.new_timer())
                return function(...)
                    local argv = { ... }
                    timer:start(ms, 0, function()
                        timer:stop()
                        vim.schedule_wrap(fn)(unpack(argv))
                    end)
                end
            end

            function M.lint()
                -- Use nvim-lint's logic first:
                -- * checks if linters exist for the full filetype first
                -- * otherwise will split filetype by "." and add all those linters
                -- * this differs from conform.nvim which only uses the first filetype that has a formatter
                local names = lint._resolve_linter_by_ft(vim.bo.filetype)

                -- Create a copy of the names table to avoid modifying the original.
                names = vim.list_extend({}, names)

                -- Add fallback linters.
                if #names == 0 then
                    vim.list_extend(names, lint.linters_by_ft['_'] or {})
                end

                -- Add global linters.
                vim.list_extend(names, lint.linters_by_ft['*'] or {})

                -- Filter out linters that don't exist or don't match the condition.
                local ctx = { filename = vim.api.nvim_buf_get_name(0) }
                ctx.dirname = vim.fn.fnamemodify(ctx.filename, ':h')
                names = vim.tbl_filter(function(name)
                    local linter = lint.linters[name]
                    if not linter then
                        vim.notify(
                            'Linter not found: ' .. name,
                            vim.log.levels.WARN
                        )
                    end
                    return linter
                        and not (
                            type(linter) == 'table'
                            and linter.condition
                            and not linter.condition(ctx)
                        )
                end, names)

                -- Run linters.
                if #names > 0 then
                    lint.try_lint(names)
                end
            end

            vim.api.nvim_create_autocmd(opts.events, {
                group = vim.api.nvim_create_augroup(
                    'nvim-lint',
                    { clear = true }
                ),
                callback = M.debounce(100, M.lint),
            })
        end,
    },
    {
        'mrcjkb/rustaceanvim',
        ft = 'rust',
        opts = function()
            vim.g.rustaceanvim = {
                server = {
                    cmd = function()
                        local mason_registry = require 'mason-registry'
                        local ra_binary = mason_registry.is_installed 'rust-analyzer'
                                and mason_registry
                                    .get_package('rust-analyzer')
                                    :get_install_path() .. '/rust-analyzer'
                            or 'rust-analyzer'
                        return { ra_binary }
                    end,
                },
            }
        end,
    },
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
                    require('trouble').toggle { mode = 'diagnostics' }
                end,
            },
            {
                '<leader>xb',
                function()
                    require('trouble').toggle {
                        mode = 'diagnostics',
                        filter = { buf = 0 },
                    }
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
