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
            providers = {
                ---@type AtlasGitHubConfig
                github = {
                    cache_ttl = 300,
                },
            },
            pulls = {
                diff = {
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
            keymaps = {
                pulls = {
                    custom = {
                        {
                            key = '<CR>',
                            desc = 'Open PR detail / run bookmark',
                            callback = function(ctx)
                                local nav =
                                    require('atlas.pulls.ui.dashboard.navigation')
                                local node = nav.current_item()

                                -- Preserve the existing bookmark/starred behavior.
                                if
                                    node
                                    and (
                                        node.kind == 'bookmark'
                                        or node.kind == 'starred'
                                    )
                                then
                                    require('atlas.pulls.ui.dashboard.controller').select_bookmark(
                                        node
                                    )
                                    return
                                end

                                if not ctx.pr then
                                    return
                                end

                                -- Open the PR detail panel and move focus into it,
                                -- matching the repository browser behavior.
                                require('atlas.pulls.ui.detail').open(ctx.pr, {
                                    provider = ctx.provider,
                                })

                                local detail_state =
                                    require('atlas.pulls.ui.detail.state')
                                if
                                    detail_state.win
                                    and vim.api.nvim_win_is_valid(detail_state.win)
                                then
                                    vim.api.nvim_set_current_win(detail_state.win)
                                end
                            end,
                        },
                    },
                },
            },
        }
        require('atlas').setup(opts)
        require('conf.atlas').setup()
    end,
}
