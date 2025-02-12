local preview = require 'snacks.picker.preview'

local M = {}

---@param ctx snacks.picker.preview.ctx
local function yadm(ctx, ...)
    local ret = { 'yadm', '-c', 'delta.' .. vim.o.background .. '=true' }
    vim.list_extend(ret, ctx.picker.opts.previewers.git.args or {})
    vim.list_extend(ret, { ... })
    return ret
end

---@param ctx snacks.picker.preview.ctx
function M.yadm_status(ctx)
    local ss = ctx.item.status
    if ss:find '^[A?]' then
        preview.file(ctx)
    else
        M.yadm_diff(ctx)
    end
end

---@param ctx snacks.picker.preview.ctx
function M.yadm_diff(ctx)
    local native = ctx.picker.opts.previewers.git.native
    local cmd = yadm(ctx, 'diff', 'HEAD')
    if ctx.item.file then
        vim.list_extend(cmd, { '--', ctx.item.file })
    end
    if not native then
        table.insert(cmd, 2, '--no-pager')
    end
    preview.cmd(cmd, ctx, { ft = not native and 'diff' or nil })
end

return M
