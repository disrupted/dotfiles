-- https://gist.github.com/MunifTanjim/8d9498c096719bdf4234321230fe3dc7
local Input = require 'nui.input'
local event = require('nui.utils.autocmd').event

local function nui_lsp_rename()
    local curr_name = vim.fn.expand '<cword>'

    local params = vim.lsp.util.make_position_params(0, 'utf-16')

    local function on_submit(new_name)
        if not new_name or #new_name == 0 or curr_name == new_name then
            -- do nothing if `new_name` is empty or not changed.
            return
        end

        -- add `newName` property to `params`.
        -- this is needed for making `textDocument/rename` request.
        params.newName = new_name

        -- send the `textDocument/rename` request to LSP server
        vim.lsp.buf_request(
            0,
            'textDocument/rename',
            params,
            function(err, result, ctx, _)
                local client = assert(vim.lsp.get_client_by_id(ctx.client_id))

                if err or not result then
                    Snacks.notify.error(
                        { 'Error requesting rename', err.message },
                        { title = 'LSP: ' .. client.name }
                    )
                    return
                end

                -- the `result` contains all the places we need to update the
                -- name of the identifier. so we apply those edits.
                vim.lsp.util.apply_workspace_edit(
                    result,
                    client and client.offset_encoding or 'utf-16'
                )

                -- display notification with the changed files
                if
                    result.documentChanges
                    and not vim.tbl_isempty(result.documentChanges)
                then
                    local msg = {
                        ('**Renamed `%s` -> `%s`**'):format(
                            curr_name,
                            new_name
                        ),
                    }

                    local total_files = vim.tbl_count(result.documentChanges)
                    table.insert(msg, '') -- empty line
                    table.insert(
                        msg,
                        string.format(
                            'Changed %s file%s. %s',
                            total_files,
                            total_files > 1 and 's' or '',
                            -- after the edits are applied, the files are not saved automatically.
                            -- let's remind ourselves to save those...
                            total_files > 1 and 'To save them run `:wa`'
                                or 'To save it run `:w`'
                        )
                    )

                    -- list changed files
                    for _, changes in pairs(result.documentChanges) do
                        table.insert(
                            msg,
                            ('- [%s] (%d changes)'):format(
                                vim.fs.relpath(
                                    assert(vim.uv.cwd()),
                                    vim.uri_to_fname(changes.textDocument.uri)
                                ),
                                #changes.edits
                            )
                        )
                    end

                    Snacks.notify.info(msg, { title = 'LSP' })
                end
            end
        )
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
            row = 2,
            col = 1,
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
    rename = nui_lsp_rename,
}
