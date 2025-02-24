local M = {}

---@return string
M.get_session_name = function()
    local name = assert(vim.uv.cwd())
    local git = require 'git'
    if git.is_repo() then
        local branch = git.current_branch()
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
