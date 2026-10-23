---@type LazeSpec
return {
    'kylechui/nvim-surround',
    main = 'nvim-surround',
    module = 'nvim-surround',
    keys = {
        -- {
        --     '<C-g>s',
        --     '<Plug>(nvim-surround-insert)',
        --     desc = 'Add a surrounding pair around the cursor (insert mode)',
        --     mode = 'i',
        -- },
        -- {
        --     '<C-g>S',
        --     '<Plug>(nvim-surround-insert-line)',
        --     desc = 'Add a surrounding pair around the cursor, on new lines (insert mode)',
        --     mode = 'i',
        -- },
        -- {
        --     'ys',
        --     '<Plug>(nvim-surround-normal)',
        --     desc = 'Add a surrounding pair around a motion (normal mode)',
        -- },
        -- {
        --     'yss',
        --     '<Plug>(nvim-surround-normal-cur)',
        --     desc = 'Add a surrounding pair around the current line (normal mode)',
        -- },
        -- {
        --     'yS',
        --     '<Plug>(nvim-surround-normal-line)',
        --     desc = 'Add a surrounding pair around a motion, on new lines (normal mode)',
        -- },
        -- {
        --     'ySS',
        --     '<Plug>(nvim-surround-normal-cur-line)',
        --     desc = 'Add a surrounding pair around the current line, on new lines (normal mode)',
        -- },
        {
            's',
            '<Plug>(nvim-surround-visual)',
            desc = 'surround selection',
            mode = 'x',
        },
        -- {
        --     'gS',
        --     '<Plug>(nvim-surround-visual-line)',
        --     desc = 'Add a surrounding pair around a visual selection, on new lines',
        --     mode = 'x',
        -- },
        {
            'ds',
            '<Plug>(nvim-surround-delete)',
            desc = 'Delete surrounding pair',
        },
        {
            'cs',
            '<Plug>(nvim-surround-change)',
            desc = 'Change surrounding pair',
        },
        -- {
        --     'cS',
        --     '<Plug>(nvim-surround-change-line)',
        --     desc = 'Change a surrounding pair, putting replacements on new lines',
        -- },
    },
    ---@module 'nvim-surround.config'
    ---@type user_options
    opts = {},
}
