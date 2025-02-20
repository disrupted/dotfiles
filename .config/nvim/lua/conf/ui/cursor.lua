local M = {}

local hl_group = 'Cursor'
local hl = vim.api.nvim_get_hl(0, { name = hl_group })
local style = 'a:Cursor/lCursor'

---@param visible boolean
local set_hl = function(visible)
    hl.blend = visible and 0 or 100
    vim.api.nvim_set_hl(0, hl_group, hl)
    if visible then
        vim.opt.guicursor:remove(style)
    else
        vim.opt.guicursor:append(style)
    end
end

M = {
    -- Show the cursor
    show = function()
        set_hl(true)
    end,
    -- Hide the cursor
    hide = function()
        set_hl(false)
    end,
}

return M
