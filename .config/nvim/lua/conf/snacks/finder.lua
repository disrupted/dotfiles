local M = {}

---@type snacks.picker.finder
M.fd_dirs = function(opts)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil

    return require('snacks.picker.source.proc').proc(
        vim.tbl_deep_extend('force', {
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
        }, opts or {})
    )
end

---@type snacks.picker.finder
M.git_dirs = function(opts)
    local cwd = vim.fs.normalize(opts and opts.cwd or vim.uv.cwd() or '.')
        or nil

    return require('snacks.picker.source.proc').proc(
        vim.tbl_deep_extend('force', {
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
        }, opts or {})
    )
end

return M
