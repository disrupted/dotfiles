local M = {}

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

    local function filter_diagnostics(diagnostic)
        -- only apply filter to Pyright & Pylance
        if not diagnostic.source:find('Py', 1, true) then
            return true
        end

        -- Allow kwargs to be unused
        if diagnostic.message == '"kwargs" is not accessed' then
            return false
        end

        -- prefix variables with an underscore to ignore
        if string.match(diagnostic.message, '"_.+" is not accessed') then
            return false
        end

        return true
    end

    vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
        function(_, params, ctx, config)
            params.diagnostics =
                vim.tbl_filter(filter_diagnostics, params.diagnostics)
            vim.lsp.diagnostic.on_publish_diagnostics(_, params, ctx, config)
        end,
        {}
    )

    vim.api.nvim_create_user_command('Format', function()
        vim.lsp.buf.format { async = true }
    end, {})

    -- Handle formatting in a smarter way
    -- If the buffer has been edited before formatting has completed, do not try to
    -- apply the changes, by Lukas Reineke
    vim.lsp.handlers['textDocument/formatting'] = function(err, result, ctx)
        if err ~= nil then
            vim.notify('error formatting', vim.lsp.log_levels.ERROR)
            return
        end

        if result == nil then
            -- vim.notify('no formatting changes', vim.lsp.log_levels.DEBUG)
            return
        end

        local bufnr = ctx.bufnr
        -- If the buffer hasn't been modified before the formatting has finished,
        -- update the buffer
        if not vim.api.nvim_buf_get_option(bufnr, 'modified') then
            local pos = vim.api.nvim_win_get_cursor(0)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            vim.lsp.util.apply_text_edits(
                result,
                bufnr,
                client and client.offset_encoding or 'utf-16'
            )
            pcall(vim.api.nvim_win_set_cursor, 0, pos)
            if bufnr == vim.api.nvim_get_current_buf() then
                vim.cmd 'noautocmd :update'
                -- vim.notify('formatting success', vim.lsp.log_levels.DEBUG)

                -- Trigger post-formatting autocommand which can be used to refresh gitsigns
                vim.api.nvim_exec_autocmds(
                    'User FormatterPost',
                    { modeline = false }
                )
            end
        end
    end

    local overridden_hover = vim.lsp.with(vim.lsp.handlers.hover, {
        border = 'single',
        focusable = false,
    })
    vim.lsp.handlers['textDocument/hover'] = function(...)
        local buf = overridden_hover(...)
        -- TODO: close the floating window directly without having to execute wincmd p twice
    end

    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
        vim.lsp.handlers.signature_help,
        { border = 'single', focusable = false, silent = true }
    )

    -- show diagnostics for current line as virtual text
    -- from https://github.com/kristijanhusak/neovim-config/blob/5977ad2c5dd9bfbb7f24b169fef01828717ea9dc/nvim/lua/partials/lsp.lua#L169
    local diagnostic_ns = vim.api.nvim_create_namespace 'diagnostics'
    function _G.show_diagnostics()
        vim.schedule(function()
            local line = vim.api.nvim_win_get_cursor(0)[1] - 1
            local bufnr = vim.api.nvim_get_current_buf()
            local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
            vim.diagnostic.show(
                diagnostic_ns,
                bufnr,
                diagnostics,
                { virtual_text = true }
            )
        end)
    end
end

function M.config()
    local home = os.getenv 'HOME'
    vim.cmd [[packadd nvim-lspconfig]]
    vim.cmd [[packadd lsp-status.nvim]]
    local lspconfig = require 'lspconfig'
    local lsp_status = require 'lsp-status'
    lsp_status.config {
        status_symbol = '',
        indicator_ok = '',
        diagnostics = false,
        current_function = false,
        -- update_interval = 100,
        -- show_filename = false,
        status_format = function(_, contents)
            return contents
        end,
    }
    lsp_status.register_progress()

    -- client log level
    vim.lsp.set_log_level 'info'

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)
    capabilities = vim.tbl_extend(
        'keep',
        capabilities or {},
        lsp_status.capabilities
    )

    if pcall(require, 'vim.lsp.nvim-semantic-tokens') then
        require('nvim-semantic-tokens').setup {
            preset = 'default',
        }
    end

    local custom_attach = function(client, bufnr)
        lsp_status.on_attach(client)

        vim.api.nvim_buf_set_option(
            bufnr,
            'formatexpr',
            'v:lua.vim.lsp.formatexpr'
        )
        vim.api.nvim_buf_set_option(bufnr, 'tagfunc', 'v:lua.vim.lsp.tagfunc')

        -- Mappings
        local function map(mode, lhs, rhs)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr })
        end
        map('n', 'gD', vim.lsp.buf.declaration)
        map('n', 'gd', vim.lsp.buf.definition)
        map('n', 'K', vim.lsp.buf.hover)
        map('n', 'gi', vim.lsp.buf.implementation)
        map('n', '<C-s>', vim.lsp.buf.signature_help)
        map('i', '<C-s>', vim.lsp.buf.signature_help)
        map('n', '<space>wa', vim.lsp.buf.add_workspace_folder)
        map('n', '<space>wr', vim.lsp.buf.remove_workspace_folder)
        map('n', '<space>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end)
        map('n', '<space>D', vim.lsp.buf.type_definition)
        map('n', '<space>r', function()
            require('conf.nui_lsp').lsp_rename()
        end)
        map('n', 'gr', function()
            require('trouble').open { mode = 'lsp_references' }
        end)
        map('n', 'gR', vim.lsp.buf.references)
        map('n', '<space>d', function()
            vim.diagnostic.open_float(0, {
                {
                    border = 'single',
                    focusable = false,
                    severity_sort = true,
                },
                scope = 'line',
            })
        end)
        map('n', '[d', function()
            vim.diagnostic.goto_prev { enable_popup = false }
        end)
        map('n', ']d', function()
            vim.diagnostic.goto_next { enable_popup = false }
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
        map('n', '<space>q', vim.diagnostic.setloclist)
        map('n', '<leader>ls', vim.lsp.buf.document_symbol)
        map('n', '<leader>lS', vim.lsp.buf.workspace_symbol)
        vim.opt.shortmess:append 'c'

        -- Set autocommands conditional on server_capabilities
        if client.server_capabilities.documentFormattingProvider then
            local augroup_lsp_format = 'lsp_format'
            vim.api.nvim_create_augroup(augroup_lsp_format, { clear = false })
            vim.api.nvim_create_autocmd('BufWritePost', {
                group = augroup_lsp_format,
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format {
                        async = true,
                        filter = function(server)
                            return server.name ~= 'sumneko_lua'
                        end,
                    }
                end,
            })
        end

        if client.server_capabilities.documentRangeFormattingProvider then
            map('n', '<leader>f', vim.lsp.buf.range_formatting)
        end

        if client.server_capabilities.documentHighlightProvider then
            local augroup_lsp_highlight = 'lsp_highlight'
            vim.api.nvim_create_augroup(
                augroup_lsp_highlight,
                { clear = false }
            )
            vim.api.nvim_create_autocmd('CursorHold', {
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

        if client.server_capabilities.semantic_tokens_full then
            vim.api.nvim_create_autocmd(
                { 'BufEnter', 'CursorHold', 'InsertLeave' },
                {
                    buffer = bufnr,
                    callback = vim.lsp.buf.semantic_tokens_full,
                }
            )
        end

        _G.show_lightbulb = function()
            require('nvim-lightbulb').update_lightbulb {
                sign = { enabled = false, priority = 99 },
                virtual_text = {
                    enabled = true,
                    text = '💡',
                    hl_mode = 'combine',
                },
            }
        end

        if client.server_capabilities.codeActionProvider then
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                buffer = bufnr,
                callback = function()
                    if vim.bo.filetype ~= 'java' then
                        show_lightbulb()
                    end
                end,
            })
            vim.keymap.set(
                'n',
                '<leader>a',
                vim.lsp.buf.code_action,
                { buffer = bufnr }
            )
            -- buf_set_keymap(
            --     'x',
            --     '<leader>a',
            --     [[:'<,'>lua require("telescope.builtin").lsp_range_code_actions({timeout = 10000, start_line = TODO, end_line = TODO})<CR>]],
            --     opts
            -- )
            -- buf_set_keymap(
            --     'v',
            --     '<leader>a',
            --     [[:Telescope lsp_range_code_actions<CR>]],
            --     opts
            -- )
        end

        if client.server_capabilities.signatureHelpProvider then
            vim.api.nvim_create_autocmd('CursorHoldI', {
                buffer = bufnr,
                callback = vim.lsp.buf.signature_help,
            })
        end

        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = bufnr,
            callback = show_diagnostics,
        })
        vim.api.nvim_create_autocmd('DiagnosticChanged', {
            buffer = bufnr,
            callback = show_diagnostics,
        })
        -- vim.notify 'LSP attached'
        -- vim.api.nvim_command ':echo "LSP attached"'
    end

    vim.cmd [[packadd pylance.nvim]]
    require 'pylance'
    lspconfig.pylance.setup {
        on_attach = custom_attach,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
        settings = {
            python = {
                analysis = {
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                    autoImportCompletions = true,
                    typeCheckingMode = 'basic', -- 'strict' or 'basic'
                    indexing = true,
                    diagnosticMode = 'workspace',
                    completeFunctionParens = false,
                    reportMissingTypeStubs = true,
                    reportImportCycles = true,
                    strictParameterNoneValue = true,
                    strictListInference = true,
                },
            },
        },
    }

    lspconfig.dockerls.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
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
        on_attach = custom_attach,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
        settings = {
            yaml = {
                customTags = {
                    '!secret',
                    '!include_dir_named',
                    '!include_dir_list',
                    '!include_dir_merge_named',
                    '!include_dir_merge_list',
                    '!lambda',
                    '!input',
                },
                -- schemas = {kubernetes = {"*.yaml"}}
            },
        },
    }

    -- JSON
    -- vscode-json-language-server
    lspconfig.jsonls.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
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
                },
            },
        },
    }

    -- HTML
    -- vscode-html-language-server
    lspconfig.html.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- CSS
    -- vscode-css-language-server
    lspconfig.cssls.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- vscode-eslint-language-server
    lspconfig.eslint.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
        capabilities = capabilities,
        flags = { debounce_text_changes = 500 },
    }

    -- TYPESCRIPT
    -- https://github.com/theia-ide/typescript-language-server
    lspconfig.tsserver.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
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

    -- NULL-LS
    local sources = require('conf.null-ls').config()

    require('null-ls').setup {
        sources = sources,
        debug = true,
        on_attach = custom_attach,
        -- Fallback to .bashrc as a project root to enable LSP on loose files
        root_dir = function(fname)
            return lspconfig.util.root_pattern(
                'tsconfig.json',
                'pyproject.toml',
                'stylua.toml',
                'dprint.json'
            )(fname) or lspconfig.util.root_pattern(
                '.eslintrc.js',
                '.git'
            )(fname) or lspconfig.util.root_pattern(
                'package.json',
                '.git/',
                '.zshrc'
            )(fname)
        end,
    }

    -- RUST
    _G.init_rust_analyzer = function()
        vim.cmd [[packadd rust-tools.nvim]]
        require('rust-tools').setup {
            server = {
                on_attach = custom_attach,
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
            },
            tools = {
                autoSetHints = true,
                hover_with_actions = true,
                runnables = { use_telescope = true },
                inlay_hints = {
                    show_parameter_hints = true,
                    parameter_hints_prefix = ' ', -- ⟵
                    other_hints_prefix = '⟹  ',
                },
            },
        }
        -- vim.api.nvim_command 'noautocmd :edit'
    end

    vim.cmd [[
        augroup rust_analyzer
            autocmd!
            autocmd FileType rust lua init_rust_analyzer()
        augroup END
        ]]

    -- GO
    lspconfig.gopls.setup {
        on_attach = custom_attach,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- LUA
    local luadev = require('lua-dev').setup {
        lspconfig = {
            on_attach = custom_attach,
            capabilities = capabilities,
            flags = { debounce_text_changes = 150 },
            settings = {
                Lua = {
                    runtime = {
                        version = 'LuaJIT',
                        -- Setup your lua path
                        path = vim.split(package.path, ';'),
                    },
                    diagnostics = { globals = { 'vim' } },
                    telemetry = { enable = false },
                },
            },
        },
    }

    lspconfig.sumneko_lua.setup(luadev)

    -- C / C++
    lspconfig.clangd.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            custom_attach(client, bufnr)
        end,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- LATEX
    lspconfig.texlab.setup {
        on_attach = custom_attach,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- DENO
    lspconfig.denols.setup {
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false -- using dprint instead
            custom_attach(client, bufnr)
        end,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
        root_dir = lspconfig.util.root_pattern 'deno.json',
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
    }

    -- JAVA
    _G.init_jdtls = function()
        local settings = {
            java = {
                import = { gradle = { wrapper = { enabled = true } } },
                format = {
                    settings = {
                        url = '~/bakdata/dependencies/format-bakdata-codestyle.xml',
                        profile = 'bakdata',
                    },
                },
                completion = { importOrder = {} },
                references = { includeDecompiledSources = false },
                saveActions = { organizeImports = true },
            },
        }

        -- add java-debug & vscode-java-test bundles
        local bundles = {
            home
                .. '/bakdata/dependencies/com.microsoft.java.debug.plugin-0.34.0.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/com.microsoft.java.test.plugin-0.33.1.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.jupiter.params_5.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/com.microsoft.java.test.runner-jar-with-dependencies.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.platform.commons_1.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.apiguardian_1.1.0.v20190826-0900.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.platform.engine_1.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.eclipse.jdt.junit4.runtime_1.1.1200.v20200214-0716.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.platform.launcher_1.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.eclipse.jdt.junit5.runtime_1.0.900.v20200513-0617.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.platform.runner_1.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.jupiter.api_5.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.platform.suite.api_1.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.jupiter.engine_5.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.vintage.engine_5.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.junit.jupiter.migrationsupport_5.6.0.v20200203-2009.jar',
            home
                .. '/bakdata/dependencies/vscode-java-test/org.opentest4j_1.2.0.v20190826-0900.jar',
        }

        vim.cmd [[packadd nvim-jdtls]]
        require('jdtls').start_or_attach {
            cmd = {
                'jdtls',
                home .. '/bakdata/workspace/' .. vim.fn.fnamemodify(
                    vim.fn.getcwd(),
                    ':p:h:t'
                ),
            },
            on_attach = function(client, bufnr)
                require('jdtls.setup').add_commands()
                require('jdtls').setup_dap { hotcodereplace = 'auto' }
                custom_attach(client, bufnr)
            end,
            -- capabilities = capabilities,
            flags = { debounce_text_changes = 150 },
            -- on_init = function(client, _)
            --     client.notify('workspace/didChangeConfiguration', {
            --         settings = settings,
            --     })
            -- end,
            settings = settings,
            init_options = {
                bundles = bundles,
            },
        }

        vim.api.nvim_create_user_command(
            'OrganizeImports',
            require('jdtls').organize_imports,
            {}
        )
        -- vim.cmd [[
        --     augroup organize_imports_on_save
        --         autocmd! * <buffer>
        --         autocmd FileType java
        --         autocmd BufWritePre <buffer> lua require'jdtls'.organize_imports()
        --     augroup END
        --     ]]
    end

    vim.cmd [[
        augroup jdtls
            autocmd!
            autocmd FileType java lua init_jdtls()
        augroup END
        ]]

    -- EXTEND LSPCONFIG
    local lspconfigs = require 'lspconfig.configs'

    -- Markdown language server
    -- https://github.com/kitten/prosemd-lsp
    lspconfigs.prosemd = {
        default_config = {
            cmd = { 'prosemd-lsp', '--stdio' },
            filetypes = { 'markdown' },
            root_dir = function(fname)
                return lspconfig.util.find_git_ancestor(fname)
                    or vim.fn.getcwd()
            end,
            settings = {},
        },
    }

    lspconfig.prosemd.setup {
        on_attach = custom_attach,
        capabilities = capabilities,
        flags = { debounce_text_changes = 150 },
    }

    -- reload if buffer has file, to attach LSP
    if
        vim.api.nvim_buf_get_name(0) ~= ''
        and vim.api.nvim_buf_is_loaded(0)
        and vim.bo.filetype ~= nil
        and vim.bo.modifiable == true
        and vim.bo.modified == false
    then
        vim.cmd 'bufdo e'
    end
end

return M
