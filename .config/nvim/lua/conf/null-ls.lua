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

    local dprint = {
        name = 'dprint',
        method = null_ls.methods.FORMATTING,
        filetypes = {
            'json',
            'markdown',
            'javascript',
            'javascriptreact',
            'typescript',
            'typescriptreact',
            'toml',
            'dockerfile',
        },
        generator = h.formatter_factory {
            command = 'dprint',
            args = {
                'fmt',
                '--config',
                vim.fn.expand '~/.config/dprint.json',
                '--stdin',
                '$FILEEXT',
            },
            to_stdin = true,
        },
    }

    -- sources
    local sources = {
        null_ls.builtins.formatting.stylua.with {
            condition = function(utils)
                return utils.root_has_file 'stylua.toml'
            end,
        },
        isortd,
        blackd,
        dprint,
        null_ls.builtins.formatting.prettierd.with {
            filetypes = {
                'vue',
                'svelte',
                'css',
                'scss',
                'less',
                'html',
                'yaml',
                'graphql',
            },
        },
        null_ls.builtins.formatting.shfmt.with {
            extra_args = { '-i', '4', '-ci' },
        },
        -- null_ls.builtins.formatting.trim_whitespace,
        -- null_ls.builtins.formatting.trim_newlines,
        null_ls.builtins.diagnostics.shellcheck,
        null_ls.builtins.code_actions.refactoring,
    }
    null_ls.config {
        sources = sources,
        debug = true,
    }
end

return M
