local M = {}

function M.config()
    require('diffview').setup {
        enhanced_diff_hl = true,
    }
end

return M
