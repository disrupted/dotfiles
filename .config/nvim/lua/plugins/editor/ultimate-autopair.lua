---@type LazeSpec
return {
    'altermo/ultimate-autopair.nvim',
    branch = 'v0.6',
    main = 'ultimate-autopair',
    module = 'ultimate-autopair',
    event = {
        'InsertEnter',
        -- 'CmdlineEnter'
    },
    config = function()
        local opts = {
            cmap = false,
            extensions = {
                cond = {
                    -- disable in comments
                    -- https://github.com/altermo/ultimate-autopair.nvim/blob/6fd0d6aa976a97dd6f1bed4d46be1b437613a52f/Q%26A.md?plain=1#L26
                    cond = {
                        function(fn)
                            return not fn.in_node 'comment'
                        end,
                    },
                },
                -- get fly mode working on strings:
                -- https://github.com/altermo/ultimate-autopair.nvim/issues/33
                fly = {
                    nofilter = true,
                },
            },
            config_internal_pairs = {
                { '"', '"', fly = true },
                { '\'', '\'', fly = true },
            },
            space2 = { enable = true },
            tabout = {
                enable = false,
                map = '<Tab>',
                hopout = true,
                do_nothing_if_fail = false,
            },
            { '\\(', '\\)' },
            { '\\[', '\\]' },
            { '\\{', '\\}' },
            {
                '<',
                '>',
                disable_start = true,
                disable_end = true,
            },
        }
        local aupair = require 'ultimate-autopair'
        aupair.init {
            aupair.extend_default(opts),
        }
    end,
}
