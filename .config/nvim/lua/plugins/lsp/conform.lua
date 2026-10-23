---@type LazeSpec
return {
    'stevearc/conform.nvim',
    main = 'conform',
    module = 'conform',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    config = function()
        local opts = (function()
            local dprint = {
                'dprint',
                timeout_ms = 5000, -- HACK: high because dprint needs to download WASM plugins on first run
            }
            local check_dprint = function(bufnr)
                if
                    require('conform').get_formatter_info('dprint', bufnr).cwd
                then
                    Snacks.notify('dprint', {
                        level = vim.log.levels.DEBUG,
                        title = 'Format',
                    })
                    return dprint
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

            vim.g.format_modifications_only = false
            local function format_git_hunks(hunks)
                for i = #hunks, 1, -1 do
                    local hunk = hunks[i]
                    if hunk ~= nil and hunk.type ~= 'delete' then
                        local start = math.max(1, hunk.added.start) -- on untracked files, start is 0
                        local last = start + hunk.added.count
                        -- nvim_buf_get_lines uses zero-based indexing -> subtract from last
                        local last_hunk_line = vim.api.nvim_buf_get_lines(
                            0,
                            last - 2,
                            last - 1,
                            true
                        )[1]
                        local range = {
                            start = { start, 0 },
                            ['end'] = { last - 1, last_hunk_line:len() },
                        }
                        require('conform').format {
                            async = false,
                            range = range,
                        }
                    end
                end
            end

            ---@module 'conform.types'
            ---@type conform.setupOpts
            return {
                formatters_by_ft = {
                    -- python = { 'ruff', lsp_format = 'last' }, -- provides `ruff check --fix`
                    luau = { 'stylua' },
                    astro = dprint,
                    json = dprint,
                    jsonc = dprint,
                    markdown = { 'pruner' },
                    javascript = dprint_prettier_none,
                    javascriptreact = dprint_prettier_none,
                    typescript = dprint_prettier_none,
                    typescriptreact = dprint_prettier_none,
                    dockerfile = dprint,
                    css = dprint,
                    html = dprint,
                    htmldjango = dprint,
                    yaml = dprint,
                    graphql = dprint,
                    pkl = { 'pkl' },
                    sql = { 'sleek' }, -- or dprint
                    svelte = dprint,
                    swift = { 'swift' },
                    nu = { 'pruner' },
                    http = { 'kulala-fmt' },
                    csv = { 'trim_newlines' },
                    tsv = { 'trim_newlines' },
                    ['_'] = {
                        'trim_newlines',
                        'trim_whitespace',
                        lsp_format = 'prefer',
                    },
                },
                format_on_save = function(bufnr)
                    -- Disable with a global or buffer-local variable
                    if
                        vim.g.disable_autoformat
                        or vim.b[bufnr].disable_autoformat
                    then
                        return
                    end
                    local hunks = require('gitsigns').get_hunks(bufnr)
                    if vim.g.format_modifications_only and hunks then
                        return format_git_hunks(hunks)
                    end
                    return { async = false }
                end,
                notify_on_error = true,
                log_level = vim.log.levels.WARN,
            }
        end)()

        local conform = require 'conform'
        conform.setup(opts)

        conform.formatters.dprint = {
            prepend_args = function(self, ctx)
                if not self:cwd(ctx) then
                    Snacks.notify('fallback to global dprint config', {
                        level = vim.log.levels.DEBUG,
                        title = 'Format',
                    })
                    return {
                        -- '--config',
                        -- vim.fs.normalize '~/.config/dprint.jsonc',
                    }
                end
            end,
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
}
