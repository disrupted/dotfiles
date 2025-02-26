vim.diagnostic.config {
    underline = true, -- use custom diagnostic handler instead to filter for which diagnostics to show an underline
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '', -- ◉✘
            [vim.diagnostic.severity.WARN] = '', -- ●▲
            [vim.diagnostic.severity.INFO] = '', -- •
            [vim.diagnostic.severity.HINT] = '', -- ·⚑
        },
        linehl = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.INFO] = '',
            [vim.diagnostic.severity.HINT] = '',
        },
        texthl = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
            [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
            [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
            [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
            [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
        },
        severity = { min = vim.diagnostic.severity.WARN },
        -- prefix = "icons", -- TODO: nvim 0.10.0
    },
    float = { header = '', source = true },
    virtual_text = false,
    virtual_lines = { current_line = true },
    update_in_insert = false,
    severity_sort = true,
}

---@param diagnostic vim.Diagnostic
---@return boolean
local has_tags = function(diagnostic)
    return diagnostic._tags
            and (diagnostic._tags.deprecated or diagnostic._tags.unnecessary)
        or false
end

---@param orig_handler vim.diagnostic.Handler
---@return vim.diagnostic.Handler
local function underline_handler(orig_handler)
    return {
        show = function(namespace, bufnr, diagnostics, opts)
            diagnostics = vim.tbl_filter(function(diagnostic)
                -- only show underline or other decorations for DiagnosticError (severity.Error)
                -- and DiagnosticDeprecated/DiagnosticUnnecessary (for all severities)
                return diagnostic.severity == vim.diagnostic.severity.ERROR
                    or has_tags(diagnostic)
            end, diagnostics)
            orig_handler.show(namespace, bufnr, diagnostics, opts)
        end,
        hide = orig_handler.hide,
    }
end

vim.diagnostic.handlers.underline =
    underline_handler(vim.diagnostic.handlers.underline)

vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump { count = -1, float = false }
end, { desc = 'Prev diagnostic' })
vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump { count = 1, float = false }
end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[e', function()
    vim.diagnostic.jump {
        count = -1,
        enable_popup = false,
        severity = vim.diagnostic.severity.ERROR,
    }
end, { desc = 'Prev error' })
vim.keymap.set('n', ']e', function()
    vim.diagnostic.jump {
        count = 1,
        enable_popup = false,
        severity = vim.diagnostic.severity.ERROR,
    }
end, { desc = 'Next error' })
vim.keymap.set('n', '[w', function()
    vim.diagnostic.jump {
        count = -1,
        enable_popup = false,
        severity = vim.diagnostic.severity.WARN,
    }
end, { desc = 'Prev warning' })
vim.keymap.set('n', ']w', function()
    vim.diagnostic.jump {
        count = 1,
        enable_popup = false,
        severity = vim.diagnostic.severity.WARN,
    }
end, { desc = 'Next warning' })

local function refresh_diagnostics_loclist()
    pcall(vim.diagnostic.setloclist, { open = false })
    if vim.tbl_isempty(vim.fn.getloclist(0)) then
        pcall(vim.cmd.lclose)
    end
end

vim.api.nvim_create_autocmd('DiagnosticChanged', {
    callback = refresh_diagnostics_loclist,
})
