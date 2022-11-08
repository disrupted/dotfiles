local M = {}

function M.config()
    require('noice').setup {
        cmdline = {
            format = {
                cmdline = { pattern = '^:', icon = ':' },
            },
        },
        lsp = { signature = { enabled = true } },
        routes = {
            {
                filter = {
                    event = 'cmdline',
                    find = '^%s*[/?]',
                },
                view = 'cmdline',
            },
        },
        presets = {
            long_message_to_split = false, -- long messages will be sent to a split
            lsp_doc_border = true, -- add a border to hover docs and signature help
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
