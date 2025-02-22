local get_breakpoints_path = function()
    local Lib = require 'auto-session.lib'
    local session_dir = require('auto-session').get_root_dir()
    local session_name = Lib.current_session_name()
    local bp_path = session_dir
        .. Lib.escape_session_name(session_name)
        .. '.json'
    return bp_path
end

local M = {}

function M.save()
    if not package.loaded.dap then
        return
    end
    local breakpoints_by_buf = require('dap.breakpoints').get()
    local savepath = get_breakpoints_path()

    if vim.tbl_isempty(breakpoints_by_buf) then
        -- If there's no breakpoints but the breakpoint file exists,
        -- erase the file
        if vim.uv.fs_stat(savepath) then
            assert(vim.uv.fs_unlink(savepath))
        end
        return
    end

    -- Map breakpoints to corresponding file
    local breakpoints_by_file = {}
    for buf, buf_bps in pairs(breakpoints_by_buf) do
        local fname = vim.api.nvim_buf_get_name(buf)
        breakpoints_by_file[fname] = buf_bps
    end

    require('file').write(savepath, vim.json.encode(breakpoints_by_file))
    vim.notify('Saved breakpoints: ' .. savepath)
end

function M.restore()
    local bp_path = get_breakpoints_path()
    -- If no breakpoints file, there's nothing to do
    if not vim.uv.fs_stat(bp_path) then
        return
    end
    local content = require('file').read(bp_path)
    assert(content)
    local breakpoints_by_file = vim.json.decode(content)

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local fname = vim.api.nvim_buf_get_name(buf)
        local breakpoints = breakpoints_by_file[fname]
        if breakpoints then
            if not vim.api.nvim_buf_is_loaded(buf) then
                vim.api.nvim_buf_call(buf, vim.cmd.edit)
            end
            for _, bp in pairs(breakpoints) do
                local opts = {
                    condition = bp.condition,
                    log_message = bp.logMessage,
                    hit_condition = bp.hitCondition,
                }
                require('dap.breakpoints').set(opts, buf, bp.line)
            end
        end
    end
end

function M.delete()
    local bp_path = get_breakpoints_path()
    assert(vim.uv.fs_unlink(bp_path))
end

return M
