---@type LazeSpec
return {
    'Davidyz/inlayhint-filler.nvim',
    main = 'inlayhint-filler',
    module = 'inlayhint-filler',
    init = function()
        vim.api.nvim_create_autocmd('LspAttach', {
            desc = 'LSP inlayhint-filler',
            callback = function(args)
                if vim.bo[args.buf].filetype ~= 'python' then
                    return
                end
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client:supports_method('textDocument/inlayHint') then
                    require('which-key').add({
                        {
                            '<Leader>I',
                            function()
                                require('inlayhint-filler').fill()
                            end,
                            mode = { 'n', 'v' },
                            buffer = args.buf,
                            desc = 'Insert inlay hint under cursor',
                            icon = '',
                        },
                    })
                end
            end,
        })
    end,
}
