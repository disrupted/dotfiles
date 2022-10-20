local M = {}

function M.config()
    require('noice').setup {
        cmdline = {
            format = {
                cmdline = { pattern = '^:', icon = ':' },
            },
        },
        lsp_progress = {
            enabled = true,
        },
        routes = {
            {
                filter = {
                    event = 'cmdline',
                    find = '^%s*[/?]',
                },
                view = 'cmdline',
            },
        },
    }
    vim.api.nvim_set_hl(0, 'NoiceVirtualText', { link = 'NormalFloat' })
    vim.api.nvim_set_hl(
        0,
        'NoiceCmdlinePopupBorder',
        { link = 'TelescopePromptBorder' }
    )
end

return M
