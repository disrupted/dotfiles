local icons = require 'conf.icons'

---@type LazeSpec
return {
    'harrisoncramer/gitlab.nvim',
    enabled = false, -- incompatible with codediff.nvim https://github.com/harrisoncramer/gitlab.nvim/issues/517
    main = 'gitlab',
    module = 'gitlab',
    dependencies = {
        'MunifTanjim/nui.nvim',
        'nvim-lua/plenary.nvim',
        'sindrets/diffview.nvim',
    },
    init = function()
        require('which-key').add {
            { '<Leader>ga', group = 'GitLab', icon = icons.git.gitlab },
            {
                '<Leader>gap',
                function()
                    local task = vim.async
                        .run(function()
                            local git = require('git').async
                            local remote_url = git.remote_url()
                            if
                                require('git').match_remote_type(remote_url)
                                ~= 'gitlab'
                            then
                                Snacks.notify.error(
                                    'Only GitLab supported',
                                    { title = 'GitLab' }
                                )
                                return
                            end
                            local branch = git.current_branch()
                            if branch == '' then
                                Snacks.notify.error(
                                    'Current ref is not a valid branch',
                                    { title = 'GitLab' }
                                )
                                return
                            end
                            if branch == git.default_branch() then
                                Snacks.notify.error(
                                    'MR is not possible on default branch',
                                    { title = 'GitLab' }
                                )
                                return
                            end

                            local mr = require('glab').mr
                            if not mr.exists() then
                                local unpushed = git.unpushed_commits()
                                if unpushed == nil then
                                    Snacks.notify.error(
                                        'Branch has no upstream, push it with -u first',
                                        { title = 'GitLab' }
                                    )
                                    return
                                elseif unpushed > 0 then
                                    Snacks.notify.warn(
                                        ('%d unpushed commit(s)'):format(
                                            unpushed
                                        ),
                                        { title = 'GitLab' }
                                    )
                                end
                                require('conf.gitlab').mr.form_create()
                            else
                                require('conf.gitlab').mr.open()
                            end
                        end)
                        :raise_on_error()
                end,
                desc = 'View or create MR',
                icon = icons.git.pull_request,
            },
            {
                '<Leader>gar',
                function()
                    require('gitlab').choose_merge_request()
                end,
                desc = 'Review MR',
                icon = icons.git.review,
            },
        }
    end,
    build = function()
        require('gitlab.server').build(true)
    end,
    opts = {
        create_mr = {
            delete_branch = true,
            squash = true,
        },
    },
}
