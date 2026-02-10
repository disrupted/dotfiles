local M = {}

---@param cmd string[]
---@return table<string, any> out
---@return string? err
local function safe_system(cmd)
    local ok, out = pcall(require('coop.vim').system, cmd)
    if not ok then
        return {}, tostring(out)
    end
    return out or {}, nil
end

---@param value any
---@return string
local function to_text(value)
    if value == nil then
        return ''
    end
    if type(value) == 'string' then
        return value
    end
    if type(value) == 'table' then
        if vim.islist(value) then
            local chunks = {}
            for _, item in ipairs(value) do
                table.insert(chunks, to_text(item))
            end
            return table.concat(chunks)
        end
        return vim.inspect(value)
    end
    return tostring(value)
end

---@param out table<string, any>?
---@return string stdout
---@return string stderr
local function normalize_system_output(out)
    out = out or {}
    local stdout = vim.trim(to_text(out.stdout))
    local stderr = vim.trim(to_text(out.stderr))
    return stdout, stderr
end

---@param stdout string
---@param stderr string
---@return string normalized_stdout
---@return string normalized_stderr
local function separate_warning_lines(stdout, stderr)
    if stderr ~= '' or stdout == '' then
        return stdout, stderr
    end

    local content_lines = {}
    local warning_lines = {}
    for _, line in ipairs(vim.split(stdout, '\n', { trimempty = true })) do
        if line:match '^Warning:' then
            table.insert(warning_lines, line)
        else
            table.insert(content_lines, line)
        end
    end

    if vim.tbl_isempty(warning_lines) or vim.tbl_isempty(content_lines) then
        return stdout, stderr
    end

    return table.concat(content_lines, '\n'), table.concat(warning_lines, '\n')
end

---@param text string
---@return string?
local function extract_pr_url(text)
    return text:match('https?://[^%s]+/pull/%d+')
end

---@async
---@param args string[]
---@return string? out
M.run = function(args)
    local cmd = { 'gh', unpack(args) }
    local out = safe_system(cmd)
    local stdout = normalize_system_output(out)
    return stdout
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
---@return string stdout
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

    local out, system_err = safe_system(cmd)
    local code = out and out.code or 0
    local stdout, stderr = normalize_system_output(out)
    stdout, stderr = separate_warning_lines(stdout, stderr)

    if system_err then
        local err = stderr ~= '' and stderr or system_err
        return '', err
    end

    local combined = table.concat(vim.tbl_filter(function(item)
        return item ~= ''
    end, { stdout, stderr }), '\n')
    local pr_url = extract_pr_url(combined)
    if pr_url then
        return pr_url, stderr ~= '' and stderr or nil
    end

    if code ~= 0 then
        local err = stderr ~= '' and stderr or stdout
        return '', err ~= '' and err or 'Failed to create PR'
    end

    if stdout ~= '' then
        return stdout, stderr ~= '' and stderr or nil
    end

    return 'PR created', stderr ~= '' and stderr or nil
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
