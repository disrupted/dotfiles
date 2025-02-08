vim.diagnostic.config {
    underline = { severity = { min = vim.diagnostic.severity.ERROR } },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '', -- ◉
            [vim.diagnostic.severity.WARN] = '', -- ●
            [vim.diagnostic.severity.INFO] = '', -- •
            [vim.diagnostic.severity.HINT] = '', -- ·
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
    update_in_insert = true,
    severity_sort = true,
}

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
