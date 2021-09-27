local lazy_require = require('feline.utils').lazy_require
local vi_mode = lazy_require 'feline.providers.vi_mode'
local lspstatus = lazy_require 'lsp-status'
local api, fn = vim.api, vim.fn

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

local function is_file(bufnr)
    local bt = api.nvim_buf_get_option(bufnr, 'buftype')
    return bt ~= 'nofile' and bt ~= 'terminal'
end

local function file_readonly(bufnr)
    if api.nvim_buf_get_option(bufnr, 'filetype') == 'help' then
        return false
    end
    if api.nvim_buf_get_option(bufnr, 'readonly') then
        return true
    end
    return false
end

local function file_modified(bufnr)
    if
        api.nvim_buf_get_option(bufnr, 'modifiable')
        and api.nvim_buf_get_option(bufnr, 'modified')
    then
        return true
    end
    return false
end

local function file_name(winid)
    local bufnr = api.nvim_win_get_buf(winid)
    local filename = api.nvim_buf_get_name(bufnr)
    filename = fn.fnamemodify(filename, ':t')

    if is_file(bufnr) and file_readonly(bufnr) then
        return filename .. ' '
    end
    if file_modified(bufnr) then
        return filename .. ' '
    end
    return filename
end

-----------------------------------------------------------------------------//
-- Components {{{1
-----------------------------------------------------------------------------//
-- Vi mode
table.insert(components.active[1], {
    provider = function(winid)
        local name = vi_mode_text[vi_mode.get_vim_mode()]
        if api.nvim_win_get_width(winid) <= 60 then
            name = name:sub(1, 1) -- shorten mode name
        end
        return ' ' .. name .. ' '
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

local function split(str, sep)
    local res = {}
    local n = 1
    for w in str:gmatch('([^' .. sep .. ']*)') do
        res[n] = res[n] or w -- only set once (so the blank after a string is ignored)
        if w == '' then
            n = n + 1
        end -- step forwards on a blank but not a string
    end
    return res
end

local function file_icon(winid)
    local icon = {
        str = ' ',
        always_visible = true,
    }

    local filename = api.nvim_buf_get_name(api.nvim_win_get_buf(winid))
    filename = fn.fnamemodify(filename, ':t')
    local extension = fn.fnamemodify(filename, ':e')

    if filename == '' then
        return icon
    end

    local icon_str, icon_hlname = require('nvim-web-devicons').get_icon(
        filename,
        extension,
        { default = false }
    )

    icon.str = string.format(' %s ', icon_str or '')

    -- icon color
    -- if icon_hlname then
    --     local fg = api.nvim_get_hl_by_name(icon_hlname, true).foreground
    --     if fg then
    --         icon.hl = { fg = string.format('#%06x', fg) }
    --     end
    -- end

    return icon
end

table.insert(components.active[1], {
    provider = '',
    icon = file_icon,
    hl = {
        bg = 'section_bg',
    },
})

local function file_path(winid)
    local bufnr = api.nvim_win_get_buf(winid)
    if not is_file(bufnr) then
        return ''
    end
    local filename = api.nvim_buf_get_name(bufnr)
    local fp = fn.fnamemodify(filename, ':~:.:h')
    local tbl = split(fp, '/')
    local len = #tbl

    if len > 2 and not len == 3 and not tbl[0] == '~' then
        return '…/' .. table.concat(tbl, '/', len - 1) .. '/' -- shorten filepath to last 2 folders
        -- alternative: only 1 containing folder using vim builtin function
        -- return '…/' .. fn.fnamemodify(fn.expand '%', ':p:h:t') .. '/'
    else
        return fp .. '/'
    end
end

table.insert(components.active[1], {
    provider = file_path,
    enabled = function(winid)
        return api.nvim_win_get_width(winid) >= 80
    end,
    hl = {
        fg = 'middlegrey',
        bg = 'section_bg',
    },
})

local function file_info(winid)
    local bufnr = api.nvim_win_get_buf(winid)
    local filename = api.nvim_buf_get_name(bufnr)
    filename = fn.fnamemodify(filename, ':t')

    -- if filename == '' then
    --     filename = '[unnamed]'
    -- end

    local readonly_str = ''
    local modified_str = ''
    if api.nvim_buf_get_option(bufnr, 'readonly') then
        readonly_str = ' '
    end

    if api.nvim_buf_get_option(bufnr, 'modified') then
        modified_str = ' '
    end

    return readonly_str .. filename .. ' ' .. modified_str
end

-- File info
table.insert(components.active[1], {
    provider = file_info,
    hl = {
        fg = 'fg',
        bg = 'section_bg',
    },
    left_sep = '',
    right_sep = {
        str = 'slant_right',
        hl = {
            fg = 'section_bg',
            bg = 'bg',
        },
    },
})

local function lsp_check_diagnostics(winid)
    if vim.tbl_isempty(vim.lsp.buf_get_clients(0)) then
        return ''
    end
    local diagnostics = vim.diagnostic.get(
        0,
        { severity = { min = vim.diagnostic.severity.INFO } }
    )
    if not vim.tbl_isempty(diagnostics) then
        return ''
    end
    local status = lspstatus.status()
    if status == ' ' then
        return ' '
    end
    if status then
        if api.nvim_win_get_width(winid) >= 80 then
            return status -- full lsp loading status
        else
            return status:sub(1, 4) -- only show lsp loading spinner
        end
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
            'Trouble',
            'dap-repl',
            '^dapui',
        },
        buftypes = {},
        bufnames = {},
    },
}
