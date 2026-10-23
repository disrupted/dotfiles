---@type LazeSpec
return {
    'folke/trouble.nvim',
    main = 'trouble',
    module = 'trouble',
    cmd = 'Trouble',
    init = function()
        require('which-key').add({
            {
                '<Leader>x',
                group = 'Trouble',
                icon = { icon = '', hl = 'DiagnosticWarn' },
            },
        })
    end,
    keys = {
        {
            '<Leader>xx',
            function()
                local started_clients =
                    require('conf.workspace.lsp').start_project_clients()
                require('conf.trouble').diagnostics.toggle(
                    'workspace_diagnostics_severe'
                )
                if not vim.tbl_isempty(started_clients) then
                    vim.defer_fn(function()
                        require('trouble').refresh('workspace_diagnostics_severe')
                    end, 500)
                end
            end,
            desc = 'Workspace diagnostics (most severe)',
        },
        {
            '<Leader>xw',
            function()
                local started_clients =
                    require('conf.workspace.lsp').start_project_clients()
                require('conf.trouble').diagnostics.toggle('workspace_diagnostics')
                if not vim.tbl_isempty(started_clients) then
                    vim.defer_fn(function()
                        require('trouble').refresh('workspace_diagnostics')
                    end, 500)
                end
            end,
            desc = 'Workspace diagnostics',
        },
        {
            '<Leader>xb',
            function()
                require('conf.trouble').diagnostics.toggle('buffer_diagnostics')
            end,
            desc = 'Buffer diagnostics',
        },
        {
            '<Leader>xq',
            function()
                require('conf.trouble').close_all()
            end,
            desc = 'Close',
        },
    },
    ---@type trouble.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
        focus = true,
        auto_refresh = false,
        fold_open = '',
        fold_closed = '',
        indent_lines = false,
        padding = false,
        keys = {
            ['<cr>'] = 'jump',
            ['<tab>'] = 'fold_toggle',
            s = {
                action = function(view)
                    local f = view:get_filter('severity')
                    local severity = ((f and f.filter.severity or 0) + 1) % 5
                    view:filter({ severity = severity }, {
                        id = 'severity',
                        template = '{hl:Title}Filter:{hl} {severity}',
                        del = severity == 0,
                    })
                end,
                desc = 'Toggle Severity Filter',
            },
        },
        modes = {
            buffer_diagnostics = {
                mode = 'diagnostics',
                title = 'Buffer Diagnostics',
                auto_refresh = true,
                filter = { buf = 0 },
            },
            workspace_diagnostics = {
                mode = 'diagnostics',
                source = 'diagnostics_pull',
                title = 'Workspace Diagnostics',
                auto_refresh = true,
                auto_close = false,
                warn_no_results = false,
                open_no_results = true,
            },
            workspace_diagnostics_severe = {
                mode = 'diagnostics',
                source = 'diagnostics_pull',
                title = 'Workspace Diagnostics (most severe)',
                auto_refresh = true,
                auto_close = false,
                warn_no_results = false,
                open_no_results = true,
                -- only the most severe diagnostics, min warning
                filter = function(items)
                    local severity = vim.diagnostic.severity.WARN
                    for _, item in ipairs(items) do
                        if item.severity > 0 then -- filter out unnecessary
                            severity = math.min(severity, math.max(item.severity))
                        end
                    end
                    return vim.tbl_filter(function(item)
                        return item.severity == severity
                    end, items)
                end,
            },
            lsp_definitions_filtered = {
                mode = 'lsp_definitions',
                ---@param items trouble.Item
                filter = function(items)
                    ---@type table<string, trouble.Item>
                    local locations = {}
                    ---@type trouble.Item[]
                    local secondary_locations = {}

                    for _, item in ipairs(items) do
                        if item.dirname:match('site%-packages') then
                            -- filter out virtualenv
                            table.insert(secondary_locations, item)
                            goto continue
                        end
                        -- find first location for each line
                        local current_location = item.filename .. item.pos[1]
                        if
                            not locations[current_location]
                            or locations[current_location].pos[2] > item.pos[2]
                        then
                            locations[current_location] = item
                        end
                        ::continue::
                    end

                    local primary_locations = vim.tbl_values(locations)
                    return vim.tbl_isempty(primary_locations) and secondary_locations
                        or primary_locations
                end,
            },
        },
    },
}
