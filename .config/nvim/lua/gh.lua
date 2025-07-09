local M = {}

---@async
---@param args string[]
---@return string? out
M.run = function(args)
    local cmd = { 'gh', unpack(args) }
    local out = require('coop.vim').system(cmd)
    if out.code ~= 0 then
        error(assert(out.stderr))
    end
    return vim.trim(out.stdout or '')
end

---@async
---@param args string[]
---@param json_fields string[]
---@return table<string, any>?
M.json = function(args, json_fields)
    assert(
        not json_fields or (json_fields and not vim.tbl_isempty(json_fields)),
        'Specify one or more JSON fields to query'
    )
    vim.list_extend(args, { '--json', table.concat(json_fields, ',') })
    local out = M.run(args)
    if out and out ~= '' then
        return vim.json.decode(out)
    end
end

---@class Label
---@field name string

---@async
---@return Label[]
M.labels = function()
    return M.json({ 'label', 'list' }, { 'name' }) or {}
end

M.pr = {}

---@async
---@param json_fields string[]
---@return table<string, any>?
M.pr.json = function(json_fields)
    return M.json({ 'pr', 'view' }, json_fields)
end

---@async
---@return boolean
M.pr.exists = function()
    return M.pr.json { 'number' } ~= nil
end

---@class gh.pr.create.Opts
---@field title string
---@field body string
---@field assignee? string
---@field draft? boolean
---@field label string[]
---@field base? string

---@async
---@param opts gh.pr.create.Opts
---@return string? stdout
---@return string? stderr
M.pr.create = function(opts)
    ---@type string[]
    local cmd = { 'gh', 'pr', 'create' }
    table.insert(cmd, '--title')
    table.insert(cmd, opts.title)
    table.insert(cmd, '--body')
    table.insert(cmd, opts.body)
    if opts.assignee and opts.assignee ~= '' then
        table.insert(cmd, '--assignee')
        table.insert(cmd, opts.assignee)
    end
    if opts.draft then
        table.insert(cmd, '--draft')
    end
    for _, label in ipairs(opts.label) do
        table.insert(cmd, '--label')
        table.insert(cmd, label)
    end
    if opts.base and opts.base ~= '' then
        table.insert(cmd, '--base')
        table.insert(cmd, opts.base)
    end

    local out = require('coop.vim').system(cmd)
    -- assert(out.code == 0)
    return out.stdout, out.stderr
end

---@async
M.pr.refresh = function()
    if
        vim.g.git_branch
        and vim.g.git_branch ~= require('git').async.default_branch()
    then
        vim.g.git_pr = M.pr.json { 'state', 'title' }
    else
        vim.g.git_pr = nil
    end
end

return M
