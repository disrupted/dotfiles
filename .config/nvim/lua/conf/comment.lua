local M = {}

---@param line string
---@return boolean
local function is_blank(line)
    return line:find('^%s*$') ~= nil
end

-- mirrors the private lookup in vim._comment so gcA matches gc
---@param pos [integer, integer] (1,0)-indexed
---@return string
function M.commentstring(pos)
    local parser = vim.treesitter.get_parser(0, nil, { error = false })
    if not parser then
        return vim.bo.commentstring
    end
    local row, col = pos[1] - 1, pos[2]
    parser:parse({ row, row + 1 })

    local captures = vim.treesitter.get_captures(0, { row, col })
    for i = #captures, 1, -1 do
        local capture = captures[i]
        local metadata = capture.metadata
        local cs = metadata['bo.commentstring']
            or (metadata[capture.id] and metadata[capture.id]['bo.commentstring'])
        if cs then
            return cs --[[@as string]]
        end
    end

    local range = { row, col, row, col + 1 }
    local result, result_depth = nil, 0
    ---@param tree vim.treesitter.LanguageTree
    ---@param depth integer
    local function traverse(tree, depth)
        if not tree:contains(range) then
            return
        end
        if depth > result_depth then
            for _, ft in ipairs(vim.treesitter.language.get_filetypes(tree:lang())) do
                local cs = vim.filetype.get_option(ft, 'commentstring') --[[@as string]]
                if cs ~= '' then
                    result, result_depth = cs, depth
                    break
                end
            end
        end
        for _, child in pairs(tree:children()) do
            traverse(child, depth + 1)
        end
    end
    traverse(parser, 1)
    return result or vim.bo.commentstring
end

-- Native resolves the commentstring at the cursor (neovim/neovim#31003). Prefer the
-- host language so helm/htmldjango template lines don't get the injected yaml/html
-- comment, else the first non-blank char. Worth upstreaming into vim._comment.
---@param line_start integer
---@param line_end integer
---@return [integer, integer]
function M.ref_position(line_start, line_end)
    local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
    local first = { line_start, 0 }
    for i, line in ipairs(lines) do
        local col = line:find('%S')
        if col then
            first = { line_start + i - 1, col - 1 }
            break
        end
    end

    local parser = vim.treesitter.get_parser(0, nil, { error = false })
    if not parser then
        return first
    end
    parser:parse({ line_start - 1, line_end })
    if vim.tbl_isempty(parser:children()) then
        return first
    end
    for i, line in ipairs(lines) do
        local row = line_start + i - 2
        local col = line:find('%S')
        while col do
            if parser:language_for_range({ row, col - 1, row, col }) == parser then
                return { row + 1, col - 1 }
            end
            col = line:find('%S', col + 1)
        end
    end
    return first
end

---@param line_start integer
---@param line_end integer
function M.toggle_lines(line_start, line_end)
    local before = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
    require('vim._comment').toggle_lines(
        line_start,
        line_end,
        M.ref_position(line_start, line_end)
    )
    for i, line in ipairs(before) do
        if is_blank(line) then
            local lnum = line_start + i - 1
            vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { line })
        end
    end
end

---@param mode? 'line'|'char'|'block'
---@return string?
function M.operator(mode)
    if mode == nil then
        vim.o.operatorfunc = 'v:lua.require\'conf.comment\'.operator'
        return 'g@'
    end
    local from = vim.api.nvim_buf_get_mark(0, '[')
    local to = vim.api.nvim_buf_get_mark(0, ']')
    if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
        return
    end
    M.toggle_lines(from[1], to[1])
end

function M.append()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()
    local last = line:find('%S%s*$')
    local cs = M.commentstring({ lnum, last and last - 1 or 0 })
    local left, right = cs:match('^(.-)%%s(.-)$')
    if not left then
        vim.notify('Option \'commentstring\' is empty.', vim.log.levels.WARN)
        return
    end
    local prefix = (last and line:sub(1, last) .. ' ' or line) .. left
    vim.api.nvim_set_current_line(prefix .. right)
    if right == '' then
        vim.cmd.startinsert({ bang = true })
    else
        vim.api.nvim_win_set_cursor(0, { lnum, #prefix })
        vim.cmd.startinsert()
    end
end

return M
