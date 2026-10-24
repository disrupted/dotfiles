---@type LazeSpec
return {
    'mfussenegger/nvim-lint',
    main = 'lint',
    module = 'lint',
    ft = { 'yaml.github' },
    config = function()
        local opts = {
            events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
            linters_by_ft = {
                ['yaml.github'] = { 'actionlint' },
            },
            -- from LazyVim: https://github.com/LazyVim/LazyVim/blob/bb36f71b77d8e15788a5b62c82a1c9ec7b209e49/lua/lazyvim/plugins/linting.lua#L16
            -- easily override linter options or add custom linters
            ---@type table<string,table>
            linters = {
                actionlint = {
                    cmd = 'jactionlint',
                },
                -- Example of using selene only when a selene.toml file is present
                -- selene = {
                --   -- dynamically enable/disable linters based on the context.
                --   condition = function(ctx)
                --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
                --   end,
                -- },
            },
        }
        local lint = require('lint')
        for name, linter in pairs(opts.linters) do
            if type(linter) == 'table' and type(lint.linters[name]) == 'table' then
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
            if not vim.bo.modifiable then
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

            -- Filter out linters that don't exist.
            names = vim.tbl_filter(function(name)
                local linter = lint.linters[name]
                if not linter then
                    Snacks.notify.warn(
                        ('Linter not found: %s'):format(name),
                        { title = 'Lint' }
                    )
                end
                return linter ~= nil
            end, names)

            -- Run linters.
            if #names > 0 then
                lint.try_lint(names)
            end
        end

        vim.api.nvim_create_autocmd(opts.events, {
            group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
            callback = Snacks.util.throttle(M.lint, { ms = 100 }),
        })
    end,
}
