local M = {}

function M.config()
    require'neogit'.setup {
        signs = {section = {"", ""}, item = {"▸", "▾"}, hunk = {"", ""}}
    }
end

return M
