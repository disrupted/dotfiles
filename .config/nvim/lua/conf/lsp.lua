local M = {}
local lsp = {}

function M.setup()
    local function sign(severity, icon)
        local hl = 'Diagnostic' .. severity
        vim.fn.sign_define(
            'DiagnosticSign' .. severity,
            { text = icon, texthl = hl, numhl = hl }
        )
    end

    sign('Error', '') -- ◉
    sign('Warn', '') -- ●
    sign('Info', '') -- •
    sign('Hint', '') -- ·

    vim.diagnostic.config {
        underline = true,
        -- signs = { severity = { min = vim.diagnostic.severity.WARN } },
        signs = true,
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
                text = '💡',
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
    vim.lsp.handlers['textDocument/formatting'] = function(err, result, ctx)
        if err then
            local err_msg = type(err) == 'string' and err or err.message
            vim.notify('error formatting: ' .. err_msg, vim.log.levels.ERROR)
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
            or vim.api.nvim_get_option_value('modified', { buf = bufnr })
        then
            return
        end

        -- local pos = vim.api.nvim_win_get_cursor(0)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        vim.lsp.util.apply_text_edits(
            result,
            bufnr,
            client and client.offset_encoding or 'utf-16'
        )
        -- pcall(vim.api.nvim_win_set_cursor, 0, pos)
        vim.api.nvim_buf_call(bufnr, function()
            vim.cmd 'silent noautocmd update'
        end)
        vim.notify('formatting success', vim.lsp.log_levels.DEBUG)

        -- Trigger post-formatting autocommand which can be used to refresh gitsigns
        -- vim.api.nvim_exec_autocmds(
        --     'User FormatterPost',
        --     { modeline = false }
        -- )
    end

    -- local overridden_hover = vim.lsp.with(vim.lsp.handlers.hover, {
    --     border = 'single',
    --     focusable = false,
    -- })
    -- vim.lsp.handlers['textDocument/hover'] = function(...)
    --     local buf = overridden_hover(...)
    --     -- TODO: close the floating window directly without having to execute wincmd p twice
    -- end

    -- vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    --     vim.lsp.handlers.signature_help,
    --     { border = 'single', focusable = false, silent = true }
    -- )

    -- vim.lsp.handlers['window/showMessage'] = function(_, result, ctx)
    --     local client = vim.lsp.get_client_by_id(ctx.client_id)
    --     local lvl = ({
    --         'ERROR',
    --         'WARN',
    --         'INFO',
    --         'DEBUG',
    --     })[result.type]
    --     vim.notify(result.message, lvl, {
    --         title = 'LSP | ' .. client.name,
    --         timeout = 10000,
    --         keep = function()
    --             return lvl == 'ERROR' or lvl == 'WARN'
    --         end,
    --     })
    -- end

    -- local function hover_wrapper(err, request, ctx, config)
    --     local bufnr, winnr = vim.lsp.handlers.hover(err, request, ctx, config)
    --     if bufnr == nil or winnr == nil then
    --         return
    --     end
    --     local contents = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    --     -- contents = vim.tbl_map(function(line)
    --     --     line = string.gsub(line, '&gt;', '>')
    --     --     line = string.gsub(line, '&lt;', '<')
    --     --     line = string.gsub(line, '&quot;', '"')
    --     --     line = string.gsub(line, '&apos;', '\'')
    --     --     line = string.gsub(line, '&ensp;', '')
    --     --     line = string.gsub(line, '&emsp;', '')
    --     --     line = string.gsub(line, '&amp;', '&')
    --     --     return line
    --     -- end, contents)
    --     contents = vim.tbl_map(function(line)
    --         local escapes = {
    --             ['&gt;'] = '>',
    --             ['&lt;'] = '<',
    --             ['&quot;'] = '"',
    --             ['&apos;'] = '\'',
    --             ['&ensp;'] = '',
    --             ['&emsp;'] = '',
    --             ['&amp;'] = '&',
    --         }
    --         return (string.gsub(line, '&[^ ;]+;', escapes))
    --     end, contents)
    --     vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
    --     vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    --     vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
    --     vim.api.nvim_win_set_height(winnr, #contents)

    --     return bufnr, winnr
    -- end

    -- vim.lsp.handlers['textDocument/hover'] = hover_wrapper

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

    local au = vim.api.nvim_create_augroup('LspAttach', { clear = true })

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
            if client.supports_method 'textDocument/documentHighlight' then
                local augroup_lsp_highlight = 'lsp_highlight'
                vim.api.nvim_create_augroup(
                    augroup_lsp_highlight,
                    { clear = false }
                )
                vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                    group = augroup_lsp_highlight,
                    buffer = bufnr,
                    callback = vim.lsp.buf.document_highlight,
                })
                vim.api.nvim_create_autocmd('CursorMoved', {
                    group = augroup_lsp_highlight,
                    buffer = bufnr,
                    callback = vim.lsp.buf.clear_references,
                })
            end
        end,
    })

    local augroup_lsp_format = vim.api.nvim_create_augroup('lsp_format', {})
    vim.api.nvim_create_autocmd('LspAttach', {
        group = au,
        desc = 'LSP format',
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client.supports_method 'textDocument/formatting' then
                vim.api.nvim_clear_autocmds {
                    group = augroup_lsp_format,
                    buffer = bufnr,
                }
                vim.api.nvim_create_autocmd('BufWritePost', {
                    group = augroup_lsp_format,
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format {
                            async = true,
                            bufnr = bufnr,
                            filter = function(server)
                                -- return server.name == 'null-ls'
                                local disabled_servers = {
                                    'eslint',
                                    'tsserver',
                                    'jsonls',
                                }
                                return not vim.tbl_contains(
                                    disabled_servers,
                                    server.name
                                )
                            end,
                        }
                    end,
                })
            end
        end,
    })

    vim.api.nvim_create_autocmd('LspAttach', {
        group = au,
        desc = 'LSP code actions',
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client.supports_method 'textDocument/codeAction' then
                vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                    buffer = bufnr,
                    callback = function()
                        lsp.show_lightbulb()
                    end,
                })
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
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                buffer = bufnr,
                callback = lsp.show_diagnostics,
            })
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
        desc = 'LSP inlay hints',
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client.supports_method 'textDocument/inlayHint' then
                vim.notify('register inlay hints', vim.lsp.log_levels.INFO)
                local lsp_inlayhints = require 'lsp-inlayhints'
                lsp_inlayhints.setup {
                    enabled_at_startup = true,
                    debug_mode = false,
                }
                lsp_inlayhints.on_attach(client, bufnr, false)
                -- TODO: native inlay hints
                --[[ vim.api.nvim_create_autocmd({
                    'BufWritePost',
                    'BufEnter',
                    'InsertLeave',
                    'FocusGained',
                    'CursorHold',
                }, {
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.inlay_hint(bufnr, true)
                    end,
                })
                -- initial request
                vim.lsp.buf.inlay_hint(bufnr) ]]
            end
        end,
    })

    vim.api.nvim_create_autocmd('LspAttach', {
        group = au,
        desc = 'LSP dim unused',
        callback = function()
            require('neodim').setup {
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
            }
        end,
    })

    --[[ vim.api.nvim_create_autocmd('LspAttach', {
        group = au,
        desc = 'LSP notify',
        callback = function()
            vim.notify 'LSP attached'
        end,
    }) ]]
end

function M.config()
    require('neodev').setup {
        override = function(root_dir, library)
            library.enabled = true
            library.plugins = true
        end,
    }
    local lspconfig = require 'lspconfig'

    -- client log level
    vim.lsp.set_log_level(vim.lsp.log_levels.INFO)

    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    require 'pylance'
    lspconfig.pylance.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- local lsp_configs = require 'lspconfig.configs'
    -- lsp_configs.pylyzer = {
    --     default_config = {
    --         cmd = { 'pylyzer' },
    --         filetypes = { 'python' },
    --         single_file_support = true,
    --         root_dir = lspconfig.util.root_pattern(
    --             '.git',
    --             'setup.py',
    --             'setup.cfg',
    --             'pyproject.toml',
    --             'requirements.txt'
    --         ),
    --         settings = {},
    --     },
    -- }

    -- lspconfig.pylyzer.setup {
    --     capabilities = capabilities,
    --     flags = { debounce_text_changes = 150 },
    -- }

    -- Synchronously organise (Go) imports.
    -- local function go_organize_imports_sync(timeout_ms)
    --     local context = { source = { organizeImports = true } }
    --     vim.validate { context = { context, 't', true } }
    --     local params = vim.lsp.util.make_range_params()
    --     params.context = context

    --     local result = vim.lsp.buf_request_sync(
    --         0,
    --         'textDocument/codeAction',
    --         params,
    --         timeout_ms
    --     )
    --     if not result then
    --         return
    --     end
    --     result = result[1].result
    --     if not result then
    --         return
    --     end
    --     local edit = result[1].edit
    --     vim.lsp.util.apply_workspace_edit(edit, 'utf-16')
    -- end

    lspconfig.dockerls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
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

    -- YAML
    -- https://github.com/redhat-developer/yaml-language-server
    lspconfig.yamlls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
        settings = {
            yaml = {
                format = { enable = false },
                -- customTags = {
                --     '!secret',
                --     '!include_dir_named',
                --     '!include_dir_list',
                --     '!include_dir_merge_named',
                --     '!include_dir_merge_list',
                --     '!lambda',
                --     '!input',
                --     '!reference sequence',
                -- },
                -- schemaStore = { enable = true },
                schemas = {
                    ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
                    ['https://json.schemastore.org/chart.json'] = '/templates/*',
                    -- ['/Users/disrupted/bakdata/kpops/docs/docs/schema/pipeline.json'] = 'pipeline.yaml',
                    -- ['/Users/disrupted/bakdata/deploy/hubble-deployment/pipeline.json'] = 'pipeline.yaml',
                    ['/Users/disrupted/bakdata/kpops/pipeline.json'] = 'pipeline.yaml',
                    ['/Users/disrupted/bakdata/kpops/docs/docs/schema/config.json'] = 'config.yaml',
                    ['/Users/disrupted/bakdata/kpops/schema_defaults.json'] = 'defaults.yaml',
                    -- ['https://bakdata.github.io/kpops/latest/schema/config.json'] = 'config.yaml',
                    -- ['https://bakdata.github.io/kpops/latest/schema/pipeline.json'] = 'pipeline.yaml',
                },
            },
        },
        -- handlers = {
        --     ['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
        --         stylize_markdown = true,
        --     }),
        -- },
    }

    -- JSON
    -- vscode-json-language-server
    lspconfig.jsonls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
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
                        fileMatch = { '.eslintrc', '.eslintrc.json' },
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
                    {
                        fileMatch = { 'pipeline.json' },
                        url = '/Users/disrupted/bakdata/nlp/kafka-nlp-deployment/pipeline.json',
                    },
                },
            },
        },
    }

    -- HTML
    -- vscode-html-language-server
    lspconfig.html.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
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

    -- CSS
    -- vscode-css-language-server
    lspconfig.cssls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- vscode-eslint-language-server
    lspconfig.eslint.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 500 },
    }

    -- TYPESCRIPT
    -- https://github.com/theia-ide/typescript-language-server
    lspconfig.tsserver.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 500 },
        root_dir = lspconfig.util.root_pattern 'package.json',
        commands = {
            OrganizeImports = {
                function()
                    local params = {
                        command = '_typescript.organizeImports',
                        arguments = { vim.api.nvim_buf_get_name(0) },
                        title = '',
                    }
                    vim.lsp.buf.execute_command(params)
                end,
            },
        },
    }

    -- RUST
    require('rust-tools').setup {
        server = {
            capabilities = capabilities,
            flags = { debounce_text_changes = 150 },
            settings = {
                ['rust-analyzer'] = {
                    diagnostics = { enable = true },
                    assist = {
                        importGranularity = 'module',
                        importPrefix = 'by_self',
                    },
                    cargo = {
                        loadOutDirsFromCheck = true,
                    },
                    procMacro = {
                        enable = true,
                    },
                    checkOnSave = {
                        allFeatures = true,
                        overrideCommand = {
                            'cargo',
                            'clippy',
                            '--workspace',
                            '--message-format=json',
                            '--all-targets',
                            '--all-features',
                        },
                    },
                },
            },
            tools = {
                runnables = { use_telescope = true },
                inlay_hints = {
                    auto = false,
                    show_parameter_hints = false,
                    parameter_hints_prefix = ' ', -- ⟵
                    other_hints_prefix = '⟹  ',
                },
            },
        },
    }

    -- GO
    lspconfig.gopls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    lspconfig.lua_ls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
        settings = {
            Lua = {
                completion = {
                    callSnippet = 'Replace',
                },
                workspace = { checkThirdParty = false },
                telemetry = { enable = false },
                diagnostics = { unusedLocalExclude = { '_*' } },
                format = { enable = false },
                hint = { enable = true },
            },
        },
    }

    -- C / C++
    lspconfig.clangd.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- LATEX
    lspconfig.texlab.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
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

    -- DENO
    -- lspconfig.denols.setup {
    --     capabilities = capabilities,
    --     flags = { debounce_text_changes = 150 },
    --     root_dir = lspconfig.util.root_pattern('deno.json', 'deno.jsonc'),
    --     filetypes = {
    --         'javascript',
    --         'javascriptreact',
    --         'javascript.jsx',
    --         'typescript',
    --         'typescriptreact',
    --         'typescript.tsx',
    --         'yaml',
    --         'json',
    --         'markdown',
    --         'html',
    --         'css',
    --     },
    --     init_options = {
    --         enable = true,
    --         lint = true,
    --         unstable = true,
    --         importMap = './import_map.json',
    --     },
    --     single_file_support = false,
    -- }

    -- Markdown language server
    -- lspconfig.prosemd_lsp.setup {
    --     capabilities = capabilities,
    --     flags = { debounce_text_changes = 150 },
    --     root_dir = function(fname)
    --         return lspconfig.util.find_git_ancestor(fname) or vim.loop.cwd()
    --     end,
    --     single_file_support = true,
    -- }

    lspconfig.terraformls.setup {
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }
end

return M
