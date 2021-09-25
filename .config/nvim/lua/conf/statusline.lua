vim.cmd [[packadd nvim-web-devicons]]
local gl = require 'galaxyline'
local utils = require 'conf.utils'
local condition = require 'galaxyline.condition'
local vcs = require 'galaxyline.providers.vcs'
local fileinfo = require 'galaxyline.providers.fileinfo'
local lspstatus = require 'lsp-status'

local gls = gl.section
gl.short_line_list = {
    'packer',
    'NvimTree',
    'Outline',
    'LspTrouble',
    'dap-repl',
    'dapui_scopes',
    'dapui_breakpoints',
    'dapui_stacks',
    'dapui_watches',
}

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
local mode_colors = {
    ['n'] = colors.green,
    ['i'] = colors.blue,
    ['c'] = colors.green,
    ['t'] = colors.blue,
    ['v'] = colors.purple,
    ['\x16'] = colors.purple,
    ['V'] = colors.purple,
    ['R'] = colors.red,
    ['s'] = colors.red,
    ['S'] = colors.red,
}
local mode_names = {
    ['n'] = 'NORMAL',
    ['i'] = 'INSERT',
    ['c'] = 'COMMAND',
    ['t'] = 'TERMINAL',
    ['v'] = 'VISUAL',
    ['\x16'] = 'V-BLOCK',
    ['V'] = 'V-LINE',
    ['R'] = 'REPLACE',
    ['s'] = 'SELECT',
    ['S'] = 'S-LINE',
}

-- Local helper functions
local buffer_not_empty = function()
    return not utils.is_buffer_empty()
end

local checkwidth = function()
    return utils.has_width_gt(35) and buffer_not_empty()
end

local is_file = function()
    return vim.bo.buftype ~= 'nofile'
end

local function has_value(tab, val)
    for _, value in ipairs(tab) do
        if value[1] == val then
            return true
        end
    end
    return false
end

local get_mode = function()
    return vim.api.nvim_get_mode()['mode']
end

local mode_color = function(mode)
    local color = mode_colors[mode]
    if color ~= nil then
        return color
    end
    print 'statusline: error looking up vi mode color'
    return colors.middlegrey
end

local vi_mode = function()
    local mode = get_mode()
    local color = mode_color(mode)
    vim.cmd('hi GalaxyViMode guibg=' .. color)
    local alias = mode_names[mode]
    if alias ~= nil then
        if not utils.has_width_gt(35) then
            alias = alias:sub(1, 1)
        end
    else
        alias = mode
    end
    return '  ' .. alias .. ' '
end

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
        return file .. '  '
    end
    if vim.bo.modifiable and vim.bo.modified then
        return file .. '  '
    end
    return file .. ' '
end

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

local function file_path()
    local fp = vim.fn.fnamemodify(vim.fn.expand '%', ':~:.:h')
    local tbl = split(fp, '/')
    local len = #tbl

    if len > 2 and not len == 3 and not tbl[0] == '~' then
        return '…/' .. table.concat(tbl, '/', len - 1) .. '/' -- shorten filepath to last 2 folders
        -- alternative: only 1 containing folder using vim builtin function
        -- return '…/' .. vim.fn.fnamemodify(vim.fn.expand '%', ':p:h:t') .. '/'
    else
        return fp .. '/'
    end
end

-- local function trailing_whitespace()
--     local trail = vim.fn.search('\\s$', 'nw')
--     if trail ~= 0 then
--         return '  '
--     else
--         return nil
--     end
-- end

-- local function tab_indent()
--     local tab = vim.fn.search('^\\t', 'nw')
--     if tab ~= 0 then
--         return ' → '
--     else
--         return nil
--     end
-- end

-- local function buffers_count()
--     local buffers = {}
--     for _, val in ipairs(vim.fn.range(1, vim.fn.bufnr('$'))) do
--         if vim.fn.bufexists(val) == 1 and vim.fn.buflisted(val) == 1 then
--             table.insert(buffers, val)
--         end
--     end
--     return #buffers
-- end

local function get_basename(file)
    return file:match '^.+/(.+)$'
end

local git_root = function()
    local git_dir = vcs.get_git_dir()
    if not git_dir then
        return ''
    end

    local git_root = git_dir:gsub('/.git/?$', '')
    return get_basename(git_root)
end

local lsp_status = function()
    if #vim.lsp.get_active_clients() > 0 then
        return lspstatus.status()
    end
    return ''
end

local lsp_check_diagnostics = function()
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

local function get_diagnostic_count(severity)
    local count = #vim.diagnostic.get(0, { severity = severity })
    return count ~= 0 and count .. ' ' or ''
end

-- Left side
gls.left[1] = {
    ViMode = {
        provider = { vi_mode },
        highlight = { colors.bg, colors.bg, 'bold' },
    },
}
gls.left[2] = {
    FileIcon = {
        provider = {
            function()
                return '  '
            end,
            'FileIcon',
        },
        condition = buffer_not_empty,
        highlight = {
            fileinfo.get_file_icon,
            colors.section_bg,
        },
    },
}
gls.left[3] = {
    FilePath = {
        provider = file_path,
        condition = function()
            return is_file() and checkwidth()
        end,
        highlight = { colors.middlegrey, colors.section_bg },
    },
}
gls.left[4] = {
    FileName = {
        provider = file_name,
        condition = buffer_not_empty,
        highlight = { colors.fg, colors.section_bg },
        separator = '',
        separator_highlight = { colors.section_bg, colors.bg },
    },
}
-- gls.left[4] = {
--     WhiteSpace = {
--         provider = trailing_whitespace,
--         condition = buffer_not_empty,
--         highlight = {colors.fg, colors.bg}
--     }
-- }
-- gls.left[5] = {
--     TabIndent = {
--         provider = tab_indent,
--         condition = buffer_not_empty,
--         highlight = {colors.fg, colors.bg}
--     }
-- }
gls.left[8] = {
    DiagnosticsCheck = {
        provider = { lsp_check_diagnostics },
        highlight = { colors.middlegrey, colors.bg },
    },
}
gls.left[9] = {
    DiagnosticError = {
        provider = function()
            return get_diagnostic_count(vim.diagnostic.severity.ERROR)
        end,
        icon = '  ',
        highlight = { colors.red, colors.bg },
        -- separator = ' ',
        -- separator_highlight = {colors.bg, colors.bg}
    },
}
-- gls.left[10] = {
--     Space = {
--         provider = function() return ' ' end,
--         highlight = {colors.section_bg, colors.bg}
--     }
-- }
gls.left[11] = {
    DiagnosticWarn = {
        provider = function()
            return get_diagnostic_count(vim.diagnostic.severity.WARN)
        end,
        icon = '  ',
        highlight = { colors.orange, colors.bg },
        -- separator = ' ',
        -- separator_highlight = {colors.bg, colors.bg}
    },
}
-- gls.left[12] = {
--     Space = {
--         provider = function() return ' ' end,
--         highlight = {colors.section_bg, colors.bg}
--     }
-- }
gls.left[13] = {
    DiagnosticInfo = {
        provider = function()
            return get_diagnostic_count(vim.diagnostic.severity.INFO)
        end,
        icon = '  ',
        highlight = { colors.blue, colors.bg },
        -- separator = ' ',
        -- separator_highlight = {colors.section_bg, colors.bg}
    },
}
gls.left[14] = {
    LspStatus = {
        provider = { lsp_status },
        -- separator = ' ',
        -- separator_highlight = {colors.bg, colors.bg},
        highlight = { colors.middlegrey, colors.bg },
    },
}

-- Right side
-- gls.right[0] = {
--     ShowLspClient = {
--         provider = 'GetLspClient',
--         condition = function()
--             local tbl = {['dashboard'] = true, [''] = true}
--             if tbl[vim.bo.filetype] then return false end
--             return true
--         end,
--         icon = ' ',
--         highlight = {colors.middlegrey, colors.bg},
--         separator = ' ',
--         separator_highlight = {colors.section_bg, colors.bg}
--     }
-- }
gls.right[1] = {
    DiffAdd = {
        provider = 'DiffAdd',
        condition = checkwidth,
        icon = '+',
        highlight = { colors.green, colors.bg },
        separator = ' ',
        separator_highlight = { colors.section_bg, colors.bg },
    },
}
gls.right[2] = {
    DiffModified = {
        provider = 'DiffModified',
        condition = checkwidth,
        icon = '~',
        highlight = { colors.orange, colors.bg },
    },
}
gls.right[3] = {
    DiffRemove = {
        provider = 'DiffRemove',
        condition = checkwidth,
        icon = '-',
        highlight = { colors.red, colors.bg },
    },
}
gls.right[4] = {
    Space = {
        provider = function()
            return ' '
        end,
        highlight = { colors.section_bg, colors.bg },
    },
}
gls.right[5] = {
    Harpoon = {
        provider = function()
            return require('harpoon.mark').status()
        end,
        highlight = { colors.middlegrey, colors.bg },
    },
}
gls.right[6] = {
    GitBranch = {
        provider = {
            function()
                return '  '
            end,
            'GitBranch',
        },
        condition = condition.check_git_workspace,
        highlight = { colors.middlegrey, colors.bg },
    },
}
gls.right[7] = {
    GitRoot = {
        provider = git_root,
        condition = function()
            return utils.has_width_gt(50) and condition.check_git_workspace
        end,
        -- icon = '  ',
        highlight = { colors.fg, colors.bg },
        separator = ' ',
        separator_highlight = { colors.middlegrey, colors.bg },
        -- separator = ' ',
        -- separator_highlight = {colors.section_bg, colors.bg}
    },
}
gls.right[8] = {
    PerCent = {
        provider = 'LinePercent',
        separator = ' ',
        separator_highlight = { colors.blue, colors.bg },
        highlight = { colors.darkgrey, colors.blue },
    },
}
-- gls.right[9] = {
--     ScrollBar = {
--         provider = 'ScrollBar',
--         highlight = {colors.purple, colors.section_bg}
--     }
-- }

-- Short status line
gls.short_line_left[1] = {
    FileIcon = {
        provider = {
            function()
                return '  '
            end,
            'FileIcon',
        },
        condition = function()
            return buffer_not_empty
                and has_value(gl.short_line_list, vim.bo.filetype)
        end,
        highlight = {
            fileinfo.get_file_icon,
            colors.section_bg,
        },
    },
}
gls.short_line_left[2] = {
    FileName = {
        provider = file_name,
        condition = buffer_not_empty,
        highlight = { colors.fg, colors.section_bg },
        separator = '',
        separator_highlight = { colors.section_bg, colors.bg },
    },
}

gls.short_line_right[1] = {
    BufferIcon = {
        provider = 'BufferIcon',
        highlight = { colors.yellow, colors.section_bg },
        separator = '',
        separator_highlight = { colors.section_bg, colors.bg },
    },
}

-- Force manual load so that nvim boots with a status line
gl.load_galaxyline()
