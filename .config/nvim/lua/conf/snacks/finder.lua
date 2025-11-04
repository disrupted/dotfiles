local M = {}

---@type snacks.picker.finder
M.fd_dirs = function(opts, ctx)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil

    return require('snacks.picker.source.proc').proc(
        ctx:opts {
            cmd = 'fd',
            args = {
                '--type',
                'd',
                '--color',
                'never',
                '-E',
                '.git',
            },
            ---@param item snacks.picker.finder.Item
            transform = function(item)
                item.cwd = cwd
                item.file = item.text
                item.dir = true
            end,
        },
        ctx
    )
end

---@type snacks.picker.finder
M.git_dirs = function(opts, ctx)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil

    return require('snacks.picker.source.proc').proc(
        ctx:opts {
            cmd = 'git',
            args = {
                '-c',
                'core.quotepath=false',
                'ls-tree',
                '-rtd',
                'HEAD',
                '--name-only',
            },
            ---@param item snacks.picker.finder.Item
            transform = function(item)
                item.cwd = cwd
                item.file = item.text
                item.dir = true
            end,
        },
        ctx
    )
end

---@param opts snacks.picker.git.status.Config
---@type snacks.picker.finder
function M.yadm_status(opts, ctx)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil
    local args = {
        '--no-pager',
        'status',
        '--porcelain=v1',
        '-z',
        '--',
        cwd,
    }

    local prev ---@type snacks.picker.finder.Item?
    return require('snacks.picker.source.proc').proc({
        opts,
        {
            sep = '\0',
            cwd = cwd,
            cmd = 'yadm',
            args = args,
            ---@param item snacks.picker.finder.Item
            transform = function(item)
                local status, file = item.text:match '^(..) (.+)$'
                if status then
                    item.cwd = cwd
                    item.status = status
                    item.file = vim.fs.relpath(cwd, '~/' .. file)
                    prev = item
                elseif prev and prev.status:find 'R' then
                    prev.rename = item.text
                    return false
                else
                    return false
                end
            end,
        },
    }, ctx)
end

return M
