local M = {}

---@return string
M.get_session_name = function()
    local name = vim.g.workspace_root
    if vim.g.git_repo then
        local branch = require('git').current_branch()
        return name .. '_' .. branch
    else
        return name
    end
end

M.save = function()
    require('resession').save(M.get_session_name(), { notify = false })
end

M.load = function()
    require('resession').load(M.get_session_name())
end

return M
