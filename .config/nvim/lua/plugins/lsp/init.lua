---@module 'lazy.types'
---@type LazySpec[]
return {
    {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        init = function()
            -- add Mason packages to $PATH; allows lazy-loading
            vim.env.PATH = vim.fn.stdpath 'data'
                .. '/mason/bin:'
                .. vim.env.PATH
        end,
        ---@module 'mason.settings'
        ---@type MasonSettings
        opts = {
            ensure_installed = {},
            registries = {
                'github:mason-org/mason-registry',
                'github:mistweaverco/zana-registry',
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
        'williamboman/mason-lspconfig.nvim',
        lazy = true,
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
                'eslint',
                'vale_ls',
                'terraformls',
                'helm_ls',
                'bashls',
                'basedpyright',
                'gitlab_ci_ls',
                'taplo',
            },
        },
    },
    {
        'folke/neoconf.nvim',
        cmd = 'Neoconf',
        opts = {},
    },
    {
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
                { path = 'snacks.nvim', words = { 'Snacks' } },
            },
        },
    },
    {
        'antosha417/nvim-lsp-file-operations',
        name = 'nvim-lsp-file-operations',
        dependencies = { 'nvim-lua/plenary.nvim' },
        lazy = true,
        opts = {},
    },
    {
        'Davidyz/inlayhint-filler.nvim',
        keys = {
            {
                '<leader>I',
                function()
                    require('inlayhint-filler').fill()
                end,
                desc = 'Insert inlay-hint under cursor',
                mode = { 'n', 'v' },
            },
        },
    },
    {
        'disrupted/pylance.nvim',
        enabled = false,
        dependencies = {
            {
                'williamboman/mason-lspconfig.nvim',
                opts = function(_, opts)
                    opts.ensure_installed = opts.ensure_installed or {}
                    table.insert(opts.ensure_installed, 'pylance')
                end,
            },
        },
        ft = 'python',
        ---@type vim.lsp.Config
        opts = {},
    },
    {
        'disrupted/kpops.nvim',
        dir = require('conf.utils').dir '~/bakdata/kpops.nvim',
        dev = require('conf.utils').dev '~/bakdata/kpops.nvim',
        dependencies = { 'gregorias/coop.nvim' },
        cmd = 'KPOps',
        ft = 'yaml.kpops',
        ---@module 'kpops.config'
        ---@type kpops.Opts
        opts = {},
    },
    {
        'neovim-plugin/lightbulb.nvim',
        event = 'LspAttach',
        opts = {
            sign = { enabled = false, priority = 99 },
            virtual_text = {
                enabled = true,
                text = '', -- 
                hl_mode = 'combine',
            },
        },
    },
    {
        'zbirenbaum/neodim',
        enabled = false, -- no longer needed because of DiagnosticUnnecessary
        event = 'LspAttach',
        ---@module 'neodim.config'
        ---@type neodim.SetupOptions
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
    },
    {
        'stevearc/conform.nvim',
        event = 'BufWritePre',
        cmd = 'ConformInfo',
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
        opts = function()
            local check_dprint = function(bufnr)
                if
                    require('conform').get_formatter_info('dprint', bufnr).cwd
                then
                    Snacks.notify('dprint', {
                        level = vim.log.levels.DEBUG,
                        title = 'Format',
                    })
                    return { 'dprint' }
                end
            end

            local check_prettier = function(bufnr)
                local prettierd =
                    require('conform').get_formatter_info('prettierd', bufnr)
                if prettierd.cwd then
                    if prettierd.available then
                        Snacks.notify('prettierd', {
                            level = vim.log.levels.DEBUG,
                            title = 'Format',
                        })
                        return { 'prettierd' }
                    else
                        Snacks.notify('prettier', {
                            level = vim.log.levels.DEBUG,
                            title = 'Format',
                        })
                        return { 'prettier' }
                    end
                end
            end

            local dprint_prettier_none = function(bufnr)
                return check_dprint(bufnr) or check_prettier(bufnr) or {}
            end

            ---@module 'conform.types'
            ---@type conform.setupOpts
            return {
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
                    javascript = dprint_prettier_none,
                    javascriptreact = dprint_prettier_none,
                    typescript = dprint_prettier_none,
                    typescriptreact = dprint_prettier_none,
                    toml = { 'dprint' },
                    dockerfile = { 'dprint' },
                    css = { 'dprint' },
                    html = { 'dprint' },
                    htmldjango = { 'dprint' },
                    yaml = { 'dprint' },
                    graphql = { 'dprint' },
                    sh = { 'shfmt' },
                    sql = { 'sleek' }, -- or dprint
                    http = {
                        'kulala',
                        -- 'injected', -- FIXME: error: vim/shared.lua:0: src: expected table, got nil
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
                log_level = vim.log.levels.WARN,
            }
        end,
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
                -- require_cwd = true,
                prepend_args = function(self, ctx)
                    if not self:cwd(ctx) then
                        Snacks.notify('fallback to global stylua config', {
                            level = vim.log.levels.DEBUG,
                            title = 'Format',
                        })
                        return {
                            '--config-path',
                            vim.fs.normalize '~/.config/nvim/stylua.toml',
                        }
                    end
                end,
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
                        Snacks.notify('fallback to global dprint config', {
                            level = vim.log.levels.DEBUG,
                            title = 'Format',
                        })
                        return {
                            '--config',
                            vim.fs.normalize '~/.config/dprint.jsonc',
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

            conform.formatters.kulala = {
                command = 'kulala-fmt',
                args = { 'format', '$FILENAME' },
                stdin = false,
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
                    method = 'textDocument/rangeFormatting',
                }

                if #clients == 0 then
                    Snacks.notify.error(
                        'Format request failed, no matching language servers',
                        { title = 'LSP' }
                    )
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
        ft = { 'yaml.github' },
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
                ['yaml.github'] = { 'actionlint' },
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
            function M.lint()
                -- Only run the linter in buffers that you can modify in order to
                -- avoid superfluous noise, notably within the handy LSP pop-ups that
                -- describe the hovered symbol using Markdown.
                if not vim.opt_local.modifiable:get() then
                    return
                end

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
                        Snacks.notify.warn(
                            ('Linter not found: %s'):format(name),
                            { title = 'Lint' }
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
                callback = Snacks.util.throttle(M.lint, { ms = 100 }),
            })
        end,
    },
    {
        'mrcjkb/rustaceanvim',
        ft = 'rust',
        init = function()
            require('conf.neotest.adapters').rust = 'rustaceanvim.neotest'
        end,
        ---@module 'rustaceanvim.config'
        ---@type rustaceanvim.Opts
        opts = {},
        config = function(_, opts)
            vim.g.rustaceanvim = opts

            local adapter = require 'rustaceanvim.neotest'()
            local adapters = require('neotest.config').adapters
            table.insert(adapters, adapter)
        end,
    },
    {
        'folke/trouble.nvim',
        cmd = 'Trouble',
        init = function()
            require('which-key').add {
                {
                    '<leader>x',
                    group = 'Trouble',
                    icon = { icon = '', hl = 'DiagnosticWarn' },
                },
            }
        end,
        keys = {
            {
                '<leader>xx',
                function()
                    require('conf.trouble').diagnostics.toggle 'workspace_diagnostics_severe'
                end,
                desc = 'Workspace diagnostics (most severe)',
            },
            {
                '<leader>xw',
                function()
                    require('conf.trouble').diagnostics.toggle 'workspace_diagnostics'
                end,
                desc = 'Workspace diagnostics',
            },
            {
                '<leader>xb',
                function()
                    require('conf.trouble').diagnostics.toggle 'buffer_diagnostics'
                end,
                desc = 'Buffer diagnostics',
            },
            {
                '<leader>xq',
                function()
                    require('trouble').toggle { mode = 'quickfix' }
                end,
                desc = 'QuickFix',
            },
        },
        ---@type trouble.Config
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            focus = true,
            auto_refresh = false,
            fold_open = '',
            fold_closed = '',
            indent_lines = false,
            padding = false,
            action_keys = { jump = { '<cr>' }, toggle_fold = { '<tab>' } },
            modes = {
                buffer_diagnostics = {
                    mode = 'diagnostics',
                    title = 'Buffer Diagnostics',
                    auto_refresh = true,
                    filter = { buf = 0 },
                },
                workspace_diagnostics = {
                    mode = 'diagnostics',
                    title = 'Workspace Diagnostics',
                    auto_refresh = true,
                    auto_close = true,
                    filter = {
                        severity = { min = vim.diagnostic.severity.WARN },
                    },
                },
                workspace_diagnostics_severe = {
                    mode = 'diagnostics',
                    title = 'Workspace Diagnostics (most severe)',
                    auto_refresh = true,
                    auto_close = true,
                    -- only the most severe diagnostics, min severity.WARN
                    filter = function(items)
                        local severity = vim.diagnostic.severity.WARN
                        for _, item in ipairs(items) do
                            severity = math.min(severity, item.severity)
                        end
                        return vim.tbl_filter(function(item)
                            return item.severity == severity
                        end, items)
                    end,
                },
            },
        },
        config = function(_, opts)
            require('trouble').setup(opts)
            vim.api.nvim_set_hl(0, 'TroubleText', { link = 'CursorLineNr' })
        end,
    },
    {
        'smjonas/inc-rename.nvim',
        enabled = false, -- FIXME: causes segfault
        cmd = 'IncRename',
        keys = {
            {
                '<leader>r',
                function()
                    return ':IncRename ' .. vim.fn.expand '<cword>'
                end,
                desc = 'LSP: rename (incremental)',
                expr = true,
            },
        },
        opts = {},
    },
}
