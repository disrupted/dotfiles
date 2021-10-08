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
    for _, map in ipairs(default_keymaps) do
        local mode = map[1]
        local lhs = map[2]
        local rhs = map[3]
        vim.api.nvim_set_keymap(mode, lhs, rhs, { silent = true })
    end
end

return M
