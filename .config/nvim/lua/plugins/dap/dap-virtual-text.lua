---@type LazeSpec
return {
    'theHamsta/nvim-dap-virtual-text',
    main = 'nvim-dap-virtual-text',
    module = 'nvim-dap-virtual-text',
    dependencies = { 'mfussenegger/nvim-dap' },
    opts = {
        enabled = true,
        enabled_commands = false,
        highlight_changed_variables = true,
        all_references = false,
        all_frames = false,
        --- A callback that determines how a variable is displayed or whether it should be omitted
        --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
        --- @param buf number
        --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
        --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
        --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
        --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
        display_callback = function(variable, _buf, _stackframe, _node, options)
            if #variable.value > 30 then
                return
            end
            -- by default, strip out new line characters
            if options.virt_text_pos == 'inline' then
                return ' = ' .. variable.value:gsub('%s+', ' ')
            else
                return variable.name .. ' = ' .. variable.value:gsub('%s+', ' ')
            end
        end,
    },
}
