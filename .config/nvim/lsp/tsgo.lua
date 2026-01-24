local inlayHints = {
    parameterNames = {
        enabled = 'all',
    },
    parameterTypes = {
        enabled = true,
    },
    variableTypes = {
        enabled = true,
    },
    -- propertyDeclarationTypes = {
    --     enabled = true,
    -- },
    -- functionLikeReturnTypes = {
    --     enabled = true,
    -- },
    enumMemberValues = {
        enabled = true,
    },
}

---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        local cmd = 'tsgo'
        -- prefer local over global executable
        local local_cmd = config.root_dir
            and vim.fs.joinpath(config.root_dir, 'node_modules', '.bin', cmd)
        if local_cmd and vim.fn.executable(local_cmd) == 1 then
            cmd = local_cmd
        end
        return vim.lsp.rpc.start({ cmd, '--lsp', '--stdio' }, dispatchers)
    end,
    filetypes = {
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
    },
    root_markers = {
        'tsconfig.json',
        'jsconfig.json',
        'package.json',
        '.git',
    },
    settings = {
        typescript = {
            inlayHints = inlayHints,
        },
        javascript = {
            inlayHints = inlayHints,
        },
    },
}
