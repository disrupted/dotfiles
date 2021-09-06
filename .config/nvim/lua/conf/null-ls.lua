local M = {}

function M.config()
    local null_ls = require 'null-ls'

    -- custom sources
    local h = require 'null-ls.helpers'

    local blackd = {
        name = 'blackd',
        method = null_ls.methods.FORMATTING,
        filetypes = { 'python' },
        generator = h.formatter_factory {
            command = 'blackd-client',
            to_stdin = true,
        },
    }

    local isortd = {
        name = 'isortd',
        method = null_ls.methods.FORMATTING,
        filetypes = { 'python' },
        generator = h.formatter_factory {
            command = 'curl',
            args = {
                '-s',
                '-X',
                'POST',
                'localhost:47393',
                '-H',
                'XX-SRC: $ROOT',
                '-H',
                'XX-PATH: $FILENAME',
                '--data-binary',
                '@-',
            },
            to_stdin = true,
        },
    }

    -- sources
    local sources = {
        null_ls.builtins.formatting.stylua.with {
            extra_args = {
                '--config-path',
                vim.fn.expand '~/.config/stylua.toml',
            },
        },
        isortd,
        blackd,
        null_ls.builtins.formatting.eslint_d,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.diagnostics.eslint_d,
        null_ls.builtins.formatting.shfmt.with {
            extra_args = { '-i', '4', '-ci' },
        },
        null_ls.builtins.diagnostics.shellcheck,
    }
    null_ls.config {
        sources = sources,
        debug = true,
    }
end

return M
