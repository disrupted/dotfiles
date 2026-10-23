---@type LazeSpec
return {
    'stevearc/resession.nvim',
    main = 'resession',
    module = 'resession',
    keys = {
        {
            '<Leader>z',
            function()
                require('conf.resession').load()
            end,
            desc = 'Restore session',
        },
    },
    init = function()
        vim.api.nvim_create_autocmd('VimLeavePre', {
            callback = function()
                if vim.v.vim_did_enter == 1 then
                    require('conf.resession').save()
                end
            end,
            desc = 'Save session on quit',
        })
    end,
    config = function()
        local extensions = { dap = {} }
        -- only pull in the scope extension if scope.nvim was actually loaded
        if package.loaded['scope'] then
            extensions.scope = {}
        end
        require('resession').setup({
            ---@param bufnr integer
            ---@return boolean
            buf_filter = function(bufnr)
                local buftype = vim.bo[bufnr].buftype
                if buftype ~= '' and buftype ~= 'acwrite' then
                    return false
                end
                if vim.api.nvim_buf_get_name(bufnr) == '' then
                    return false
                end
                return true
            end,
            extensions = extensions,
        })
    end,
}
