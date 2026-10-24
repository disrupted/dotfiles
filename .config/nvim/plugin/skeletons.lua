local dir = vim.fs.joinpath(vim.fn.stdpath('config'), 'skeletons')

local skeletons = {
    { pattern = 'lua/plugins/**.lua', file = 'laze-spec.lua' },
    { pattern = 'lsp/*.lua', file = 'lsp.lua' },
    { pattern = '*.tsx', file = 'typescript-react.tsx' },
    { pattern = 'tests/**.py', file = 'python-pytest.py' },
}

local au = vim.api.nvim_create_augroup('skeletons', { clear = true })

local function buffer_is_empty(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    return #lines == 1 and lines[1] == ''
end

local function load_skeleton(args, file)
    if vim.b[args.buf].skeleton_loaded or vim.fn.getfsize(args.file) > 0 then
        return
    end

    if not vim.bo[args.buf].modifiable then
        return
    end

    local path = vim.fs.joinpath(dir, file)
    if vim.fn.filereadable(path) == 0 then
        vim.notify(('skeleton not readable: %s'):format(path), vim.log.levels.WARN)
        return
    end

    vim.b[args.buf].skeleton_loaded = true

    local lines = vim.fn.readfile(path)
    if buffer_is_empty(args.buf) then
        vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, lines)
    else
        vim.api.nvim_buf_set_lines(args.buf, 0, 0, false, lines)
    end

    vim.bo[args.buf].modified = true
end

for _, skeleton in ipairs(skeletons) do
    vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
        group = au,
        pattern = skeleton.pattern,
        desc = 'Load skeleton for new or empty files',
        callback = function(args)
            load_skeleton(args, skeleton.file)
        end,
    })
end
