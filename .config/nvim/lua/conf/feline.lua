local lazy_require = require('feline.utils').lazy_require
local vi_mode = lazy_require 'feline.providers.vi_mode'
local lspstatus = lazy_require 'lsp-status'

local colors = {
    bg = '#282c34',
    fg = '#abb2bf',
    section_bg = '#38393f',
    blue = '#61afef',
    green = '#98c379',
    purple = '#c678dd',
    orange = '#e5c07b',
    red = '#e06c75',
    yellow = '#e5c07b',
    darkgrey = '#2c323d',
    middlegrey = '#8791A5',
}
local vi_mode_colors = {
    NORMAL = 'green',
    OP = 'red',
    INSERT = 'blue',
    VISUAL = 'purple',
    LINES = 'purple',
    BLOCK = 'purple',
    REPLACE = 'red',
    ['V-REPLACE'] = 'purple',
    ENTER = 'blue',
    MORE = 'blue',
    SELECT = 'orange',
    COMMAND = 'green',
    SHELL = 'green',
    TERM = 'blue',
    NONE = 'yellow',
}
local vi_mode_text = {
    NORMAL = 'NORMAL',
    OP = 'OPERATOR',
    INSERT = 'INSERT',
    VISUAL = 'VISUAL',
    LINES = 'V-LINE',
    BLOCK = 'V-BLOCK',
    REPLACE = 'REPLACE',
    ['V-REPLACE'] = 'V-REPLACE',
    ENTER = 'ENTER',
    MORE = 'MORE',
    SELECT = 'SELECT',
    COMMAND = 'COMMAND',
    SHELL = 'SHELL',
    TERM = 'TERMINAL',
    NONE = 'NONE',
}

local components = {
    active = { {}, {} }, -- statusline sections left & right
    inactive = { {} },
}

local function file_readonly()
    if vim.bo.filetype == 'help' then
        return false
    end
    if vim.bo.readonly then
        return true
    end
    return false
end

local function file_name()
    local file = vim.fn.expand '%:t'
    if not file then
        return ''
    end
    if file_readonly() then
        return file .. ' '
    end
    if vim.bo.modifiable and vim.bo.modified then
        return file .. ' '
    end
    return file
end

-----------------------------------------------------------------------------//
-- Components {{{1
-----------------------------------------------------------------------------//
-- Vi mode
table.insert(components.active[1], {
    provider = function()
        return ' ' .. vi_mode_text[vi_mode.get_vim_mode()] .. ' '
    end,
    icon = '',
    hl = function()
        return {
            fg = 'bg',
            bg = vi_mode.get_mode_color(),
            style = 'bold',
        }
    end,
})

-- File icon
-- table.insert(components.active[1], {
--     provider = function()
--         local fname = vim.fn.expand '%:t'
--         local fext = vim.fn.expand '%:e'
--         local icon = require('nvim-web-devicons').get_icon(fname, fext)
--         if icon == nil then
--             icon = ''
--         end
--         return icon
--     end,
--     hl = function()
--         return {
--             fg = 'fg',
--             bg = 'section_bg',
--         }
--     end,
--     left_sep = '  ',
--     right_sep = ' ',
-- })

-- File info
table.insert(components.active[1], {
    provider = {
        name = 'file_info',
        opts = {
            file_modified_icon = '',
            file_readonly_icon = ' ',
            type = 'relative',
        },
    },
    hl = {
        fg = 'fg',
        bg = 'section_bg',
    },
    right_sep = {
        str = 'slant_right',
        hl = {
            fg = 'section_bg',
            bg = 'bg',
        },
    },
})

local function lsp_check_diagnostics()
    if vim.tbl_isempty(vim.lsp.buf_get_clients(0)) then
        return ''
    end
    local diagnostics = vim.diagnostic.get(
        0,
        { severity = { min = vim.diagnostic.severity.INFO } }
    )
    if vim.tbl_isempty(diagnostics) and lspstatus.status() == ' ' then
        return ' '
    end
    return ''
end

table.insert(components.active[1], {
    provider = lsp_check_diagnostics,
    hl = {
        fg = 'middlegrey',
        bg = 'bg',
    },
})

local function get_diagnostic_count(severity)
    local count = #vim.diagnostic.get(0, { severity = severity })
    return count ~= 0 and count .. ' ' or ''
end

table.insert(components.active[1], {
    provider = function()
        return get_diagnostic_count(vim.diagnostic.severity.ERROR)
    end,
    icon = '  ',
    hl = {
        fg = 'red',
        bg = 'bg',
    },
})
table.insert(components.active[1], {
    provider = function()
        return get_diagnostic_count(vim.diagnostic.severity.WARN)
    end,
    icon = '  ',
    hl = {
        fg = 'orange',
        bg = 'bg',
    },
})
table.insert(components.active[1], {
    provider = function()
        return get_diagnostic_count(vim.diagnostic.severity.INFO)
    end,
    icon = '  ',
    hl = {
        fg = 'blue',
        bg = 'bg',
    },
})
local lsp_status = function()
    if #vim.lsp.get_active_clients() > 0 then
        return lspstatus.status()
    end
    return ''
end
table.insert(components.active[1], {
    provider = function()
        return lsp_status()
    end,
    hl = {
        fg = 'middlegrey',
        bg = 'bg',
    },
})

-- RIGHT
table.insert(components.active[2], {
    provider = 'git_diff_added',
    icon = '+',
    hl = {
        fg = 'green',
        bg = 'bg',
    },
    right_sep = ' ',
})
table.insert(components.active[2], {
    provider = 'git_diff_changed',
    icon = '~',
    hl = {
        fg = 'orange',
        bg = 'bg',
    },
    right_sep = ' ',
})
table.insert(components.active[2], {
    provider = 'git_diff_removed',
    icon = '-',
    hl = {
        fg = 'red',
        bg = 'bg',
    },
    right_sep = ' ',
})
table.insert(components.active[2], {
    provider = 'git_branch',
    -- icon = ' ',
    hl = {
        fg = 'middlegrey',
        bg = 'bg',
    },
    left_sep = ' ',
})

table.insert(components.inactive[1], {
    provider = file_name,
    hl = {
        fg = 'fg',
        bg = 'section_bg',
    },
    right_sep = {
        str = 'slant_right',
        hl = {
            fg = 'section_bg',
            bg = 'bg',
        },
    },
})

-----------------------------------------------------------------------------//
-- }}}1
-----------------------------------------------------------------------------//

require('feline').setup {
    colors = colors,
    vi_mode_colors = vi_mode_colors,
    components = components,
    force_inactive = {
        filetypes = {
            '^packer$',
            'NvimTree',
            '^qf$',
            '^help$',
            'Outline',
            'LspTrouble',
            'dap-repl',
            '^dapui',
        },
        buftypes = {},
        bufnames = {},
    },
}
