return {
    cmp_sources = setmetatable({
        LSP = '',
        Snippets = '󰐱', -- 󰩫  󱡄 󰐱
        Buffer = '󰈙',
        Path = '󰉋',
        cmdline = '',
    }, {
        __index = function()
            return ''
        end,
    }),
    documents = {
        file = '',
        file_empty = '',
        file_modified = '',
        files = '',
        folder = '',
        folder_empty = '',
        open_folder = '',
        open_folder_empty = '',
        sym_link = '',
        symlink_folder = '',
        import = '',
    },
    git = {
        git = '󰊢',
        branch = '',
        github = '',
        gitlab = '',
        staged = '',
        modified = '󰄱', -- aka unstaged
        ignored = '',
        added = '',
        deleted = '',
        renamed = '',
        unmerged = '',
        untracked = '*',
        commit = '󰜘',
        issue = '',
        pull_request = '',
        review = '',
        squash = '󰃸',
        checkout = '󰇚',
        diff = '',
    },
    test = {
        notify = '',
        passed = '',
        failed = '',
        skipped = '', -- 
        running = '', -- FIXME:  symbol rendered incorrectly in Ghostty
        unknown = '',
        watching = '',

        -- summary tree
        child_prefix = '├',
        final_child_prefix = '└',
        child_indent = '│',
        final_child_indent = ' ',

        -- node icon shown after connector
        expanded = '┐',
        collapsed = '─',
        non_collapsible = '',
    },
    diagnostics = {
        error = '',
        warning = '', -- 
        info = '',
    },
    kinds = {
        Array = '󰅪',
        Boolean = '◩',
        Class = '󰙅',
        Color = '󰏘',
        Control = '',
        Collapsed = '',
        Constant = '󰏿',
        Constructor = '',
        Copilot = '',
        Enum = '',
        EnumMember = '',
        Event = '',
        Field = '',
        File = '󰈙',
        Folder = '󰉋',
        Function = '󰊕',
        Interface = '󰕘',
        Key = '󰌋',
        Keyword = '󰌋',
        Method = '',
        Module = '',
        Namespace = '󰌗',
        Null = '󰢤',
        Number = '󰎠',
        Object = '',
        Operator = '󰆕',
        Package = '󰆦',
        Property = '',
        Reference = '󰋺',
        Snippet = '󱡄',
        String = '󰉾',
        Struct = '󱡠',
        Text = '', -- 󰉿󰦨
        TypeParameter = '󰊄', -- 
        Unit = '', -- 
        Unknown = '?', -- 
        Value = '',
        Variable = '󰀫',
    },
    arrows = {
        up = '',
        down = '',
        left = '',
        right = '',
        -- up = '',
        -- down = '',
        -- left = '',
        -- right = '',
    },
    misc = {
        quickfix = '󱡠',
        bug = '',
        ellipsis = '…',
        search = '',
        window = '',
    },
}
