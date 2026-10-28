---@type LazeSpec
return {
    'emrearmagan/atlas.nvim',
    main = 'atlas',
    module = 'atlas',
    cmd = 'Atlas',
    keys = {},
    config = function()
        ---@module 'atlas'
        ---@type AtlasConfig
        local opts = {
            ui = {
                statusline = {
                    ---@param buf integer
                    ---@param win integer
                    ---@param context "atlas"|"diff"
                    ---@return boolean
                    enable = function(buf)
                        if vim.tbl_contains({ 'atlas-ui.detail' }, vim.bo[buf].ft) then
                            return false
                        end
                        return true
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
                    paths = {
                        ['bakdata/*'] = '~/bakdata/*',
                    },
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
    end,
}
