vim.o.cmdheight = 0
vim.o.messagesopt = table.concat({
    'hit-enter',
    'history:1000',
    'progress:c',
    'maxheight:50',
    'pager:<CR>',
    'timeout:4000',
}, ',')

local ui2 = require 'vim._core.ui2'
ui2.enable {
    enable = true,
    msg = {
        targets = {
            -- key is a Lua pattern matched against the message ID
            default = 'msg', -- fallback for kinds without an explicit entry below
            empty = 'cmd',
            confirm = 'cmd',
            emsg = 'pager',
            echo = 'msg',
            echomsg = 'msg',
            echoerr = 'pager',
            completion = 'cmd',
            list_cmd = 'pager',
            lua_error = 'pager',
            lua_print = 'msg',
            progress = 'msg',
            rpc_error = 'pager',
            quickfix = 'msg',
            search_cmd = 'cmd',
            search_count = 'cmd',
            shell_cmd = 'pager',
            shell_err = 'pager',
            shell_out = 'pager',
            shell_ret = 'msg',
            undo = 'msg',
            verbose = 'pager',
            wildlist = 'cmd',
            wmsg = 'msg',
            typed_cmd = 'cmd',
        },
        dialog = { height = 0.5 },
        msg = { height = 0.5 },
        pager = { height = 0.8 },
    },
}

local skip_messages = {
    -- Write
    '%d+L, %d+B written',

    -- Search
    '; after #%d+',
    '; before #%d+',
    'E486: Pattern not found:',

    -- Edit
    '%d+ less lines',
    '%d+ fewer lines',
    '%d+ more lines',
    '%d+ change;',
    '%d+ line less;',
    '%d+ more lines?;',
    '%d+ fewer lines;?',
    '1 more line',
    '1 line less',
    '^Hunk %d+ of %d+$',
    'Already at newest change',
    'Already at oldest change',

    '%d lines yanked',
    'no lines in buffer',

    -- Undo/Redo
    '%d+ changes?;',
    ' changes; brefore #',
    ' changes; after #',
    ' 1 change; before #',
    ' 1 change; after #',

    -- Move lines
    ' lines moved',
    ' lines indented',
}

local normalized_content = function(src)
    if type(src) ~= 'table' then
        return tostring(src or '')
    end

    local list = {}
    for _, chunk in ipairs(src) do
        if type(chunk) == 'table' and chunk[2] then
            list[#list + 1] = chunk[2]
        end
    end

    return table.concat(list)
end

local messages = require 'vim._core.ui2.messages'
local orig_msg_show = messages.msg_show
messages.msg_show = function(
    kind,
    content,
    replace_last,
    history,
    append,
    id,
    trigger
)
    local msg = normalized_content(content)

    for _, pat in ipairs(skip_messages) do
        if msg:find(pat) then
            return
        end
    end

    orig_msg_show(kind, content, replace_last, history, append, id, trigger)
end

vim.api.nvim_create_autocmd('LspProgress', {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end
        local value = ev.data.params.value
        vim.api.nvim_echo({ { value.message or 'done' } }, false, {
            id = 'lsp.' .. ev.data.client_id .. '.' .. value.title,
            kind = 'progress',
            source = 'vim.lsp',
            title = ('[%s] %s'):format(client.name, value.title),
            status = value.kind ~= 'end' and 'running' or 'success',
            percent = value.percentage,
        })
    end,
})
