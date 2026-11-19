local group = vim.api.nvim_create_augroup('EmmyluaLibrary', {})

vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'VeryLazy',
    once = true,
    callback = function()
        require('conf.emmylua').write()
    end,
})

vim.api.nvim_create_autocmd('PackChanged', {
    group = group,
    callback = function(args)
        if args.data.kind ~= 'update' then -- update keeps the plugin path
            require('conf.emmylua').write()
        end
    end,
})
