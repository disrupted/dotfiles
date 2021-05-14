local M = {}

function M.config()
    vim.g.bufferline = {
        -- Enable/disable animations
        animation = false,

        auto_hide = true,

        -- Enable/disable icons
        -- if set to 'numbers', will show buffer index in the tabline
        -- if set to 'both', will show buffer index and icons in the tabline
        icons = true,
        icon_separator_active = '▎',
        icon_separator_inactive = ' ',
        icon_close_tab = '',
        icon_close_tab_modified = ' ',

        -- Enable/disable close button
        closable = false,

        -- Enables/disable clickable tabs
        --  - left-click: go to buffer
        --  - middle-click: delete buffer
        clickable = true,

        -- If set, the letters for each buffer in buffer-pick mode will be
        -- assigned based on their name. Otherwise or in case all letters are
        -- already assigned, the behavior is to assign letters in order of
        -- usability (see order below)
        semantic_letters = true,

        -- Sets the maximum padding width with which to surround each tab
        maximum_padding = 2,
    }
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap('n', '<space>x', '<cmd>BufferDelete<CR>', opts)
end

return M
