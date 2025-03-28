local M = {}

---@class glab.run.Opts
---@field args string[]

local glab = {
    ---@async
    ---@param opts glab.run.Opts
    ---@return string out
    run = function(opts)
        local cmd = opts.args
        table.insert(cmd, 1, 'glab')
        local out = require('coop.vim').system(cmd)
        -- assert(out.code == 0)
        return vim.trim(out.stdout or '')
    end,
}

M.mr = {}

---@async
---@return table<string, any>?
M.mr.json = function()
    local out = glab.run { args = { 'mr', 'view', '--output', 'json' } }
    if out ~= '' then
        return vim.json.decode(out)
    end
end

---@async
---@return boolean
M.mr.exists = function()
    return M.mr.json() and true or false
end

---@class glab.mr.create.Opts
---@field title string
---@field body string
---@field assignee? string
---@field target? string base branch

---@async
---@param opts glab.mr.create.Opts
---@return string? stdout
---@return string? stderr
M.mr.create = function(opts)
    ---@type string[]
    local cmd = { 'glab', 'mr', 'create' }
    table.insert(cmd, '--title')
    table.insert(cmd, opts.title)
    table.insert(cmd, '--description')
    table.insert(cmd, opts.body)
    if opts.assignee then
        table.insert(cmd, '--assignee')
        table.insert(cmd, opts.assignee)
    end
    if opts.target then
        table.insert(cmd, '--target-branch')
        table.insert(cmd, opts.target)
    end
    table.insert(cmd, '--remove-source-branch')
    table.insert(cmd, '--squash-before-merge')
    table.insert(cmd, '--yes') -- skip confirm

    local out = require('coop.vim').system(cmd)
    -- assert(out.code == 0)
    return out.stdout, out.stderr
end

---@async
M.mr.refresh = function()
    -- align schema with gh CLI so that it is uniform and easier to consume
    ---@param json table<string, any>?
    ---@return table<string, any>?
    local function transform(json)
        if not json then
            return
        end
        -- https://gitlab.com/gitlab-org/cli/-/blob/main/commands/mr/mrutils/mrutils.go
        local state_map = {
            opened = 'OPEN',
            draft = 'OPEN',
            merged = 'MERGED',
            -- closed
        }
        json.state = state_map[json.state]
        return json
    end

    if vim.g.git_branch then
        vim.g.git_pr = transform(M.mr.json())
    else
        vim.g.git_pr = nil
    end
end

return M
