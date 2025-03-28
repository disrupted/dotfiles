local M = {}

-- copy of require('blink.cmp').get_lsp_capabilities() to allow lazy-loading blink.cmp
local cmp_capabilities = {
    textDocument = {
        completion = {
            completionItem = {
                snippetSupport = true,
                commitCharactersSupport = false, -- todo:
                documentationFormat = { 'markdown', 'plaintext' },
                deprecatedSupport = true,
                preselectSupport = false, -- todo:
                tagSupport = { valueSet = { 1 } }, -- deprecated
                insertReplaceSupport = true, -- todo:
                resolveSupport = {
                    properties = {
                        'documentation',
                        'detail',
                        'additionalTextEdits',
                        'command',
                        'data',
                    },
                },
                insertTextModeSupport = {
                    -- todo: support adjustIndentation
                    valueSet = { 1 }, -- asIs
                },
                labelDetailsSupport = true,
            },
            completionList = {
                itemDefaults = {
                    'commitCharacters',
                    'editRange',
                    'insertTextFormat',
                    'insertTextMode',
                    'data',
                },
            },

            contextSupport = true,
            insertTextMode = 1, -- asIs
        },
    },
}

-- custom capabilities
local capabilities = {
    workspace = {
        didChangeWatchedFiles = {
            dynamicRegistration = true,
        },
    },
}

M.capabilties = vim.tbl_deep_extend(
    'force',
    vim.lsp.protocol.make_client_capabilities(),
    cmp_capabilities,
    capabilities
)

---@param override lsp.ClientCapabilities
M.extend_client_capabilities = function(override)
    return vim.tbl_deep_extend('force', M.capabilties, override)
end

return M
