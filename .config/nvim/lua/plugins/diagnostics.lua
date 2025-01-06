return {
    {
        'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
        event = 'DiagnosticChanged',
        init = function()
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'lazy',
                desc = 'disable lsp_lines diagnostics for Lazy',
                callback = function()
                    local ns = vim.api.nvim_create_namespace 'lazy'
                    vim.diagnostic.config({ virtual_lines = false }, ns)
                end,
            })
        end,
        opts = function()
            vim.diagnostic.config {
                virtual_lines = { only_current_line = true },
            }
        end,
    },
    {
        'rachartier/tiny-inline-diagnostic.nvim',
        enabled = false,
        event = 'DiagnosticChanged',
        opts = {
            signs = {
                left = '',
                right = '',
                diag = '●',
                arrow = '    ',
                up_arrow = '    ',
                vertical = ' │',
                vertical_end = ' └',
            },
            hi = {
                error = 'DiagnosticError',
                warn = 'DiagnosticWarn',
                info = 'DiagnosticInfo',
                hint = 'DiagnosticHint',
                arrow = 'NonText',
                -- background = 'CursorLine',
                -- mixing_color = 'None',
                mixing_color = '#e7e7e7',
            },
            blend = {
                factor = 0.27,
            },
        },
    },
}
