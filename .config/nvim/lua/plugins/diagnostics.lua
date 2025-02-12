---@type LazySpec[]
return {
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
