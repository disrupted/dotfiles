--- Main files picker (fff, falling back to snacks' smart picker).
---
--- `<C-d>` narrows the search to directories (several via `<Tab>` in the
--- dirs picker, repeated `<C-d>` adds more), `<C-b>` clears them, like the
--- grep and workspace symbols pickers. fff gets a glob constraint prepended
--- to the query, so its index and frecency ranking stay intact.
local M = {}

--- fff glob constraint matching files below `dirs` (relative to the cwd).
--- A bare `dir/` token only filters alongside other search text, and several
--- of them are ANDed, so use one brace glob instead.
---@param dirs string[]
---@return string?
function M.glob(dirs)
    if #dirs == 0 then
        return nil
    end
    if #dirs == 1 then
        return dirs[1] .. '/**'
    end
    return '{' .. table.concat(dirs, ',') .. '}/**'
end

---@param dirs string[]
---@return string
local function title(dirs)
    if #dirs == 0 then
        return 'Files'
    end
    return ('Files [%s]'):format(table.concat(
        vim.tbl_map(function(dir)
            return dir .. '/'
        end, dirs),
        ', '
    ))
end

---@param dirs string[]
---@return snacks.picker.Config
local function fff_source(dirs)
    local source = vim.deepcopy(require('fff-snacks.find_files').source)
    source.formatters = nil
    -- fff-snacks pads files without git status with a virtual "  " (to align
    -- with the status icon); snacks' own file format (grep etc.) doesn't
    local format = source.format --[[@as snacks.picker.format]]
    source.format = function(item, picker)
        local ret = format(item, picker)
        if not item.status then
            for i, chunk in ipairs(ret) do
                if chunk.virtual and chunk[1] == '  ' then
                    table.remove(ret, i)
                    break
                end
            end
        end
        return ret
    end
    local finder = source.finder --[[@as fun(opts: table, ctx: snacks.picker.finder.ctx): any]]
    local glob = M.glob(dirs)
    if glob then
        source.finder = function(opts, ctx)
            -- fff-snacks only reads ctx.filter.search; leave the real filter
            -- (prompt, highlights) untouched
            local filter = setmetatable(
                { search = vim.trim(glob .. ' ' .. ctx.filter.search) },
                { __index = ctx.filter }
            )
            return finder(opts, setmetatable({ filter = filter }, { __index = ctx }))
        end
    end
    return source
end

---@param dirs string[]
---@return snacks.picker.Config
local function smart_source(dirs)
    return {
        source = 'smart',
        finders = {
            'buffers',
            'recent',
            vim.g.git_repo and 'git_files' or 'files',
        },
        hidden = true,
        matcher = { sort_empty = true },
        filter = #dirs > 0 and { paths = (function()
            local paths = {}
            for _, dir in ipairs(dirs) do
                paths[vim.fs.joinpath(assert(vim.uv.cwd()), dir)] = true
            end
            return paths
        end)() } or { cwd = true },
    }
end

---@param opts? {search?: string, dirs?: string[]}
---@return snacks.Picker?
function M.pick(opts)
    opts = opts or {}
    local dirs = opts.dirs or {}
    local cwd = assert(vim.uv.cwd())

    ---@type snacks.picker.Config
    local source
    if pcall(require, 'fff') and pcall(require, 'fff-snacks') then
        source = fff_source(dirs)
    else
        Snacks.notify('fff unavailable, falling back to builtin smart picker')
        source = smart_source(dirs)
    end

    ---@param picker snacks.Picker
    ---@param next_dirs string[]
    local function reopen(picker, next_dirs)
        local search = picker.input:get()
        picker:close()
        M.pick({ search = search, dirs = next_dirs })
    end

    source = vim.tbl_deep_extend('force', source, {
        title = title(dirs),
        search = opts.search,
        actions = {
            calculate_file_truncate_width = function(self)
                local width = self.list.win:size().width
                self.opts.formatters.file.truncate = width - 6
            end,
            pick_dirs = function(self, _)
                ---@diagnostic disable-next-line: undefined-field
                Snacks.picker.dirs({
                    title = 'Narrow Files to Directories',
                    cwd = cwd,
                    confirm = function(dir_picker, _)
                        local next_dirs = vim.list_extend({}, dirs)
                        for _, item in ipairs(dir_picker:selected({ fallback = true })) do
                            local path = Snacks.picker.util.path(item)
                            local rel = path and vim.fs.relpath(cwd, path)
                            if rel and rel ~= '.' and not vim.list_contains(next_dirs, rel) then
                                next_dirs[#next_dirs + 1] = rel
                            end
                        end
                        dir_picker:close()
                        reopen(self, next_dirs)
                    end,
                })
            end,
            clear_dirs = function(self, _)
                if #dirs > 0 then
                    reopen(self, {})
                end
            end,
        },
        win = {
            input = {
                keys = {
                    ['<C-d>'] = {
                        'pick_dirs',
                        mode = { 'i', 'n' },
                        desc = 'Narrow to directories',
                    },
                    ['<C-b>'] = {
                        'clear_dirs',
                        mode = { 'i', 'n' },
                        desc = 'Clear directories',
                    },
                },
            },
            list = {
                on_buf = function(self)
                    self:execute('calculate_file_truncate_width')
                end,
            },
            preview = {
                on_buf = function(self)
                    self:execute('calculate_file_truncate_width')
                end,
                on_close = function(self)
                    self:execute('calculate_file_truncate_width')
                end,
            },
        },
    })

    local picker = Snacks.picker(source)
    if not picker then
        return nil -- picker was closed
    end
    picker.list.win:on('VimResized', function()
        picker:action('calculate_file_truncate_width')
    end)
    return picker
end

return M
