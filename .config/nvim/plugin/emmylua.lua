require('conf.emmylua').write()

vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('EmmyluaLibrary', {}),
    callback = function(args)
        if args.data.kind ~= 'update' then -- update keeps the plugin path
            require('conf.emmylua').write()
        end
    end,
})
