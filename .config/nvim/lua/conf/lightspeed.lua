local M = {}

function M.config()
    require('lightspeed').setup {
        ignore_case = true,
        exit_after_idle_msecs = { labeled = 4000, unlabeled = 3000 },
    }
end

return M
