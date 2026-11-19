---@return table<string, string> paths `namespace/repo` of each remote -> checkout under ~/work
local function work_repo_paths()
    local paths, scores = {}, {}
    for _, git_dir in ipairs(vim.fn.glob('~/work/*/*/.git', true, true)) do
        if vim.fn.isdirectory(git_dir) == 1 then
            local dir = vim.fs.dirname(git_dir)
            local remote
            for _, line in ipairs(vim.fn.readfile(git_dir .. '/config')) do
                local section = line:match('^%[(.*)%]')
                if section then
                    remote = section:match('^remote "(.+)"$')
                end
                local url = remote and line:match('^%s*url%s*=%s*(%S+)')
                local repo = url
                    and (
                        url:match('^%a[%w+.-]*://[^/]+/(.+)$')
                        or url:match('^[^/:]+:(.+)$')
                    )
                if repo then
                    repo = repo:gsub('/+$', ''):gsub('%.git$', '')
                    -- extra remotes (forks, upstreams) must not claim another checkout's repo
                    local score = (
                        vim.fs.basename(repo) == vim.fs.basename(dir) and 2 or 0
                    )
                        + (remote == 'origin' and 1 or 0)
                    if score > (scores[repo] or -1) then
                        paths[repo], scores[repo] = dir, score
                    end
                end
            end
        end
    end
    return paths
end

---@type LazeSpec
return {
    'emrearmagan/atlas.nvim',
    main = 'atlas',
    module = 'atlas',
    cmd = 'Atlas',
    keys = {
        {
            '<Leader>gci',
            function()
                local pipelines = require('atlas.commands.pipelines')
                local number = vim.g.git_pr and vim.g.git_pr.number
                pipelines.open(number and tostring(number) or '.')
            end,
            desc = 'CI: current PR',
        },
    },
    config = function()
        ---@module 'atlas'
        ---@type AtlasConfig
        local opts = {
            ui = {
                statusline = {
                    ---@param buf integer
                    ---@param win integer
                    ---@return boolean
                    enable = function(buf)
                        if
                            vim.tbl_contains({
                                'atlas-ui.detail',
                            }, vim.bo[buf].ft)
                        then
                            return false
                        end
                        return true
                    end,
                    ---@param buf integer
                    ---@param win integer
                    layout = function()
                        local components = require('atlas.ui.statusline.components')
                        return {
                            components.user,
                            ---@param ctx AtlasStatuslineContext
                            function(ctx)
                                if ctx.pr then
                                    ---@type AtlasStatuslineSegment[]
                                    return {
                                        {
                                            text = '#' .. ctx.pr.id,
                                            hl_group = 'AtlasFooterInfo',
                                        },
                                        {
                                            text = ctx.pr.title,
                                            hl_group = 'StatusLine',
                                        },
                                    }
                                end
                            end,
                            '%=',
                            components.help,
                        }
                    end,
                },
            },
            providers = {
                ---@type AtlasGitHubConfig
                github = {
                    cache_ttl = 300,
                },
            },
            pulls = {
                diff = {
                    open_cmd = 'CodeDiff',
                    review_panel = { hidden = false },
                    lsp = { enabled = true },
                },
                repo_config = {
                    paths = work_repo_paths(),
                },
                github = {
                    views = {
                        {
                            name = 'This repo',
                            key = '1',
                            layout = 'compact',
                            current_repo = true,
                            search = 'is:pr is:open sort:updated-desc',
                        },
                        {
                            name = 'All my PRs',
                            key = '2',
                            layout = 'compact',
                            search = 'involves:@me',
                        },
                    },
                    bookmarks = {
                        key = 'S',
                        label = 'Search',
                        items = {
                            ['Drafts'] = 'is:pr is:draft author:@me',
                            ['Review requested'] = 'is:pr is:open review-requested:@me',
                        },
                    },
                },
            },
            issues = {
                ---@type AtlasGitHubIssuesConfig
                github = {
                    views = {
                        {
                            name = 'This repo',
                            key = '1',
                            layout = 'compact',
                            current_repo = true,
                            search = 'is:issue is:open sort:updated-desc',
                        },
                        {
                            name = 'Assigned',
                            key = '2',
                            layout = 'compact',
                            search = 'assignee:@me is:open sort:updated-desc',
                        },
                        {
                            name = 'Created',
                            key = '3',
                            layout = 'compact',
                            search = 'author:@me is:open sort:updated-desc',
                        },
                        {
                            name = 'Mentioned',
                            key = '4',
                            layout = 'compact',
                            search = 'mentions:@me is:open sort:updated-desc',
                        },
                    },
                },
            },
        }
        require('atlas').setup(opts)

        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'atlas-ui.dashboard',
            group = vim.api.nvim_create_augroup('atlas_dashboard_cr', { clear = true }),
            callback = function(args)
                local kind = vim.api.nvim_buf_get_name(args.buf):match('Atlas Pulls')
                        and 'pulls'
                    or 'issues'
                local field = kind == 'pulls' and 'pr' or 'issue'
                -- defer so this runs after atlas sets its own buffer keymaps
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(args.buf) then
                        return
                    end
                    vim.keymap.set('n', '<CR>', function()
                        local base = 'atlas.' .. kind .. '.ui.dashboard'
                        local node = require(base .. '.navigation').current_item()
                        if not node then
                            return
                        end
                        if node.kind == 'bookmark' or node.kind == 'starred' then
                            require(base .. '.controller').select_bookmark(node)
                        elseif
                            node[field]
                            and not require('atlas.' .. kind .. '.ui.detail').is_open()
                        then
                            require(base).toggle_detail()
                        end
                    end, { buffer = args.buf, desc = 'Open details' })
                end)
            end,
        })
    end,
}
