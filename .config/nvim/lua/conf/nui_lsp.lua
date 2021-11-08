-- https://gist.github.com/MunifTanjim/8d9498c096719bdf4234321230fe3dc7
vim.cmd [[packadd nui.nvim]]
local Input = require 'nui.input'
local event = require('nui.utils.autocmd').event
local utils = require 'utils'

local function handler(err, result, ctx, _)
    if err or not result then
        vim.notify(
            ('Error running LSP query \'%s\': %s'):format(ctx.method, err),
            vim.log.levels.ERROR
        )
        return
    end

    local curr_name = vim.fn.expand '<cword>'

    -- the `result` contains all the places we need to update the
    -- name of the identifier. so we apply those edits.
    vim.lsp.util.apply_workspace_edit(result)

    -- display notification with the changed files
    -- https://github.com/mattleong/CosmicNvim/blob/85fea07d98a340813898c35ea8266efdd826fe88/lua/cosmic/core/theme/ui.lua
    if result.changes then
        local msg = {}
        local new_name = ''
        print(vim.inspect(result.changes))
        for f, c in pairs(result.changes) do
            new_name = c[1].newText
            table.insert(
                msg,
                ('%d changes: %s'):format(#c, utils.get_relative_path(f))
            )
        end
        vim.notify(
            msg,
            vim.log.levels.INFO,
            { title = { ('Rename: %s -> %s'):format(curr_name, new_name), '' } }
        )
    end

    -- after the edits are applied, the files are not saved automatically.
    -- let's remind ourselves to save those...
    local total_files = vim.tbl_count(result.changes)
    print(
        string.format(
            'Changed %s file%s. To save them run \':wa\'',
            total_files,
            total_files > 1 and 's' or ''
        )
    )
end

local function nui_lsp_rename()
    local curr_name = vim.fn.expand '<cword>'

    local params = vim.lsp.util.make_position_params()

    local function on_submit(new_name)
        if not new_name or #new_name == 0 or curr_name == new_name then
            -- do nothing if `new_name` is empty or not changed.
            return
        end

        -- add `newName` property to `params`.
        -- this is needed for making `textDocument/rename` request.
        params.newName = new_name

        -- send the `textDocument/rename` request to LSP server
        vim.lsp.buf_request(0, 'textDocument/rename', params, handler)
    end

    local popup_options = {
        -- border for the window
        border = {
            style = 'rounded',
            text = {
                top = '[Rename]',
                top_align = 'left',
            },
        },
        -- highlight for the window.
        highlight = 'Normal:Normal',
        -- place the popup window relative to the
        -- buffer position of the identifier
        relative = {
            type = 'buf',
            position = {
                -- this is the same `params` we got earlier
                row = params.position.line,
                col = params.position.character,
            },
        },
        -- position the popup window on the line below identifier
        position = {
            row = 1,
            col = 0,
        },
        size = {
            width = math.max(#curr_name + 10, 25),
            height = 1,
        },
    }

    local input = Input(popup_options, {
        -- set the default value to current name
        default_value = curr_name,
        -- pass the `on_submit` callback function we wrote earlier
        on_submit = on_submit,
        prompt = '',
    })

    input:mount()

    -- make it easier to move around long words
    local kw = vim.opt.iskeyword - '_' - '-'
    vim.bo.iskeyword = table.concat(kw:get(), ',')

    -- go into normal mode
    vim.schedule(function()
        vim.api.nvim_command 'stopinsert'
    end)

    -- close on <esc> in normal mode
    input:map('n', '<esc>', input.input_props.on_close, { noremap = true })

    -- close when cursor leaves the buffer
    input:on(event.BufLeave, input.input_props.on_close, { once = true })
end

return {
    lsp_rename = nui_lsp_rename,
}
