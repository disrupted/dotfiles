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

    local function dprint_config()
        local lsputil = require 'lspconfig.util'
        local path = lsputil.path.join(vim.loop.cwd(), 'dprint.json')
        print(path)
        if lsputil.path.exists(path) then
            print 'path exists'
            return path
        end
        print 'path doesnt exist'
        return vim.fn.expand '~/.config/dprint.json'
    end

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
            'css',
        },
        generator = h.formatter_factory {
            command = 'dprint',
            -- condition = function(utils)
            --     return utils.root_has_file 'dprint.json'
            -- end,
            args = {
                'fmt',
                '--config',
                -- dprint_config(),
                -- require('lspconfig.util').path.join(
                --     vim.loop.cwd(),
                --     'dprint.json'
                -- ),
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
                -- 'css',
                -- 'scss',
                'less',
                'html',
                'yaml',
                'graphql',
            },
            -- condition = function(utils)
            --     return not utils.root_has_file 'dprint.json'
            -- end,
        },
        null_ls.builtins.formatting.uncrustify.with {
            condition = function(utils)
                return utils.root_has_file 'uncrustify.cfg'
            end,
            extra_args = {
                '-c',
                require('lspconfig.util').path.join(
                    vim.loop.cwd(),
                    'uncrustify.cfg'
                ),
            }, -- for neovim/neovim repo
        },
        null_ls.builtins.formatting.shfmt.with {
            extra_args = { '-i', '4', '-ci' },
        },
        -- null_ls.builtins.formatting.trim_whitespace,
        -- null_ls.builtins.formatting.trim_newlines,
        null_ls.builtins.diagnostics.shellcheck,
        null_ls.builtins.diagnostics.actionlint.with {
            -- based on https://github.com/jose-elias-alvarez/null-ls.nvim/pull/804
            runtime_condition = function()
                local path =
                    vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                return path:match 'github/workflows/' ~= nil
            end,
        },
        -- null_ls.builtins.code_actions.refactoring,
        null_ls.builtins.code_actions.gitrebase,
    }
    return sources
end

return M
