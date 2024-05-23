vim.diagnostic.config {
    underline = true,
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
    float = { header = false, source = 'always' },
    virtual_text = false,
    -- virtual_text = {
    --     -- spacing = 4,
    --     -- prefix = '■', -- ■ 
    -- },
    update_in_insert = true,
    severity_sort = true,
}

vim.keymap.set('n', '<leader>cd', function()
    vim.diagnostic.open_float {
        {
            scope = 'line',
            border = 'single',
            focusable = false,
            severity_sort = true,
        },
    }
end, { desc = 'Line diagnostics' })
vim.keymap.set('n', '[d', function()
    vim.diagnostic.goto_prev { float = false }
end, { desc = 'Prev diagnostic' })
vim.keymap.set('n', ']d', function()
    vim.diagnostic.goto_next { float = false }
end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[e', function()
    vim.diagnostic.goto_prev {
        enable_popup = false,
        severity = vim.diagnostic.severity.ERROR,
    }
end, { desc = 'Prev error' })
vim.keymap.set('n', ']e', function()
    vim.diagnostic.goto_next {
        enable_popup = false,
        severity = vim.diagnostic.severity.ERROR,
    }
end, { desc = 'Next error' })
vim.keymap.set('n', '[w', function()
    vim.diagnostic.goto_prev {
        enable_popup = false,
        severity = vim.diagnostic.severity.WARN,
    }
end, { desc = 'Prev warning' })
vim.keymap.set('n', ']w', function()
    vim.diagnostic.goto_next {
        enable_popup = false,
        severity = vim.diagnostic.severity.WARN,
    }
end, { desc = 'Next warning' })

local diagnostic_ns = vim.api.nvim_create_namespace 'diagnostics'
-- show diagnostics for current line as virtual text
-- from https://github.com/kristijanhusak/neovim-config/blob/5977ad2c5dd9bfbb7f24b169fef01828717ea9dc/nvim/lua/partials/lsp.lua#L169
local function show_diagnostics()
    vim.schedule(function()
        local line = vim.api.nvim_win_get_cursor(0)[1] - 1
        local bufnr = vim.api.nvim_get_current_buf()
        if
            vim.api.nvim_get_option_value('buftype', { buf = bufnr })
            == 'nofile'
        then
            return
        end
        local diagnostics = vim.diagnostic.get(bufnr, {
            lnum = line,
            severity = { min = vim.diagnostic.severity.INFO },
        })
        vim.diagnostic.show(
            diagnostic_ns,
            bufnr,
            diagnostics,
            { virtual_text = true }
        )
    end)
end

vim.api.nvim_create_autocmd(
    { 'DiagnosticChanged', 'CursorHold', 'CursorHoldI' },
    {
        callback = show_diagnostics,
    }
)

local function refresh_diagnostics_loclist()
    pcall(vim.diagnostic.setloclist, { open = false })
    if vim.tbl_isempty(vim.fn.getloclist(0)) then
        pcall(vim.cmd.lclose)
    end
end

vim.api.nvim_create_autocmd('DiagnosticChanged', {
    callback = refresh_diagnostics_loclist,
})
