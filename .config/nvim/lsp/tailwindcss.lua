---@type vim.lsp.Config
return {
    cmd = { 'bunx', '--bun', 'tailwindcss-language-server', '--stdio' },
    filetypes = {
        -- CSS
        'css',
        -- JS
        'javascript',
        'javascriptreact',
        'typescript',
        'typescriptreact',
        -- MIXED
        'svelte',
    },
    settings = {
        tailwindCSS = {
            validate = true,
            lint = {
                cssConflict = 'warning',
                invalidApply = 'error',
                invalidScreen = 'error',
                invalidVariant = 'error',
                invalidConfigPath = 'error',
                invalidTailwindDirective = 'error',
                recommendedVariantOrder = 'warning',
            },
            classAttributes = {
                'class',
                'className',
                'class:list',
                'classList',
            },
            includeLanguages = {
                templ = 'html',
            },
        },
    },
    before_init = function(_, config)
        if not config.settings then
            config.settings = {}
        end
        if not config.settings.editor then
            config.settings.editor = {}
        end
    end,
    workspace_required = true,
    root_dir = function(bufnr, on_dir)
        local root = vim.fs.root(bufnr, { 'tailwind.config.js' })
        on_dir(root)
    end,
}
