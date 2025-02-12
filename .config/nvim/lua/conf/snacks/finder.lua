local M = {}

---@type snacks.picker.finder
M.fd_dirs = function(opts, ctx)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil

    return require('snacks.picker.source.proc').proc({
        opts,
        {
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
    }, ctx)
end

---@type snacks.picker.finder
M.git_dirs = function(opts, ctx)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil

    return require('snacks.picker.source.proc').proc({
        opts,
        {
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
    }, ctx)
end

return M
