local gh = require 'octo.gh'

local M = {}

M.pr = {}

---@param opts? octo.pr.open.Opts
M.pr.open = function(opts)
    ---@class octo.pr.open.Opts
    ---@field octo boolean
    ---@field browser boolean
    opts = vim.tbl_extend('keep', opts or {}, {
        octo = true,
        browser = false,
    })
    if opts.octo then
        Snacks.notify 'Opening PR...'
        vim.cmd 'Octo pr'
    end
    if opts.browser then
        vim.cmd 'Octo pr browser'
    end
end

---@param opts? octo.pr.open.Opts
M.pr.create = function(opts)
    vim.ui.input({
        prompt = 'PR title',
        default = require('conf.git').last_commit_msg(),
        win = { ft = 'gitcommit' },
    }, function(title)
        if not title or title == '' then
            return
        end

        vim.ui.input({
            prompt = 'PR body',
            win = { ft = 'markdown' },
        }, function(body)
            if not body then
                return
            end

            gh.pr.create {
                title = title,
                body = body,
                assignee = 'disrupted',
                draft = true,
                opts = {
                    ---@param out string?
                    ---@param stderr string?
                    cb = function(out, stderr)
                        if stderr and stderr ~= '' then
                            Snacks.notify.error(stderr)
                            if
                                not stderr:match 'Warning: ' -- e.g. 'Warning: 2 uncommitted changes'
                            then
                                -- abort if not just a warning
                                return
                            end
                        end

                        Snacks.notify 'created PR'
                        vim.defer_fn(function()
                            M.pr.open(opts)
                        end, 2000)
                    end,
                },
            }
        end)
    end)
end

---@param opts? octo.pr.open.Opts
M.pr.open_or_create = function(opts)
    gh.run {
        args = {
            'pr',
            'view',
            '--json',
            'number',
            '-q',
            '.number',
        },
        ---@param out string?
        cb = function(out)
            if out ~= '' then
                M.pr.open(opts)
                return
            end
            M.pr.create(opts)
        end,
    }
end

return M
