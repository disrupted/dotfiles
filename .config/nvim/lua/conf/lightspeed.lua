local M = {}

function M.setup()
    local default_keymaps = {
        { 'n', 's', '<Plug>Lightspeed_s' },
        { 'n', 'S', '<Plug>Lightspeed_S' },
        { 'x', 's', '<Plug>Lightspeed_s' },
        { 'x', 'S', '<Plug>Lightspeed_S' },
        { 'o', 'z', '<Plug>Lightspeed_s' },
        { 'o', 'Z', '<Plug>Lightspeed_S' },
        { 'o', 'x', '<Plug>Lightspeed_x' },
        { 'o', 'X', '<Plug>Lightspeed_X' },
        { 'n', 'f', '<Plug>Lightspeed_f' },
        { 'n', 'F', '<Plug>Lightspeed_F' },
        { 'x', 'f', '<Plug>Lightspeed_f' },
        { 'x', 'F', '<Plug>Lightspeed_F' },
        { 'o', 'f', '<Plug>Lightspeed_f' },
        { 'o', 'F', '<Plug>Lightspeed_F' },
        { 'n', 't', '<Plug>Lightspeed_t' },
        { 'n', 'T', '<Plug>Lightspeed_T' },
        { 'x', 't', '<Plug>Lightspeed_t' },
        { 'x', 'T', '<Plug>Lightspeed_T' },
        { 'o', 't', '<Plug>Lightspeed_t' },
        { 'o', 'T', '<Plug>Lightspeed_T' },
    }
    for _, m in ipairs(default_keymaps) do
        vim.api.nvim_set_keymap(m[1], m[2], m[3], { silent = true })
    end
end

function M.config()
    require('lightspeed').setup {
        x_mode_prefix_key = '<c-x>', -- TODO
    }
end

return M
