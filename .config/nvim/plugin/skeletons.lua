local skeletons = {
    lua = '~/.config/nvim/skeletons/nvim-lazy-spec.lua',
    tsx = '~/.config/nvim/skeletons/typescript-react.tsx',
    python = '~/.config/nvim/skeletons/python-pytest.py',
}

local au = vim.api.nvim_create_augroup('skeletons', {})
vim.api.nvim_create_autocmd('BufNewFile', {
    group = au,
    pattern = { '*.lua', '*.tsx', 'tests/**.py' },
    desc = 'Load skeleton when creating new file',
    callback = function(args)
        local ft = vim.api.nvim_get_option_value('filetype', { buf = args.buf })
        local skeleton = skeletons[ft]
        vim.cmd('read ' .. skeleton .. ' | 1delete_')
    end,
})
