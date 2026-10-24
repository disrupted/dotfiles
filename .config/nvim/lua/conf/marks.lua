-- Harpoon replacement built on native marks.
--
-- Set:    mA .. mZ
-- Jump:   'A .. 'Z  (first non-blank of the line)
--         `A .. `Z  (exact position)
-- Delete: :delm A   (or <C-x> in the picker)
-- List:   <leader>m
--
-- Uppercase marks point to files and survive restarts via ShaDa. `init.lua`
-- assigns a separate shadafile per workspace root, so each project keeps its
-- own marks without any custom persistence.
local M = {}

--- Keep file marks A-Z, drop previous-context and special marks ('0-9, '", ...).
---@param item snacks.picker.finder.Item
---@return snacks.picker.finder.Item|false
function M.transform(item)
    if not item.label or not item.label:match('^[A-Z]$') then
        return false
    end
    return item
end

--- List marks, jump to the selected one or delete it with <C-x>.
function M.picker()
    require('snacks').picker.marks({
        title = 'Marks',
        global = true,
        ['local'] = false,
        layout = { preset = 'dropdown' },
        transform = M.transform,
    })
end

function M.setup()
    vim.keymap.set('n', '<leader>m', M.picker, { desc = 'Marks' })
end

return M
