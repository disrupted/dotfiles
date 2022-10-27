local skeletons = {
    lua = '~/.config/nvim/skeletons/nvim-conf-module.lua',
    tsx = '~/.config/nvim/skeletons/typescript-react.tsx',
    python = '~/.config/nvim/skeletons/python-pytest.py',
}

local au = vim.api.nvim_create_augroup('skeletons', {})
vim.api.nvim_create_autocmd('BufNewFile', {
    group = au,
    pattern = { '*.lua', '*.tsx', 'tests/**.py' },
    desc = 'Load skeleton when creating new file',
    callback = function(args)
        local ft = vim.api.nvim_buf_get_option(args.buf, 'filetype')
        local skeleton = skeletons[ft]
        vim.cmd('read ' .. skeleton .. ' | 1delete_')
    end,
})
