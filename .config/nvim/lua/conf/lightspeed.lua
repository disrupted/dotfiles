local M = {}

function M.setup()
    local default_keymaps = {
        { { 'n', 'x' }, 's', '<Plug>Lightspeed_s' },
        { { 'n', 'x' }, 'S', '<Plug>Lightspeed_S' },
        { 'o', 'z', '<Plug>Lightspeed_s' },
        { 'o', 'Z', '<Plug>Lightspeed_S' },
        { 'o', 'x', '<Plug>Lightspeed_x' },
        { 'o', 'X', '<Plug>Lightspeed_X' },
        { { 'n', 'x', 'o' }, 'f', '<Plug>Lightspeed_f' },
        { { 'n', 'x', 'o' }, 'F', '<Plug>Lightspeed_F' },
        { { 'n', 'x', 'o' }, 't', '<Plug>Lightspeed_t' },
        { { 'n', 'x', 'o' }, 'T', '<Plug>Lightspeed_T' },
    }
    for _, m in ipairs(default_keymaps) do
        vim.keymap.set(m[1], m[2], m[3], { silent = true })
    end
end

function M.config()
    require('lightspeed').setup {
        ignore_case = true,
        exit_after_idle_msecs = { labeled = 4000, unlabeled = 3000 },
    }
end

return M
