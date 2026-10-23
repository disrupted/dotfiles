-- Wraps the built-in diagnostics source and triggers a workspace/diagnostic
-- pull request when the source is fetched. This ensures that diagnostics for
-- files not currently open as buffers are included in workspace diagnostics
-- modes, since Neovim only fires DiagnosticChanged for unloaded buffers after
-- an explicit pull request -- it does not happen automatically at startup.
--
-- The built-in diagnostics source already handles unloaded buffers correctly
-- once DiagnosticChanged fires for them; the only missing piece is the trigger.
-- After the initial pull, DiagnosticChanged drives subsequent refreshes naturally.

local function diagnostics()
    return require('trouble.sources.diagnostics')
end

---@type trouble.Source
return {
    highlights = {
        Message = 'TroubleText',
        ItemSource = 'Comment',
        Code = 'Comment',
    },
    setup = function()
        diagnostics().setup()
    end,
    get = function(cb, ctx)
        -- Always trigger a pull so results stay fresh.
        -- DiagnosticChanged will fire and trigger auto_refresh when results arrive.
        vim.lsp.buf.workspace_diagnostics()
        diagnostics().get(cb, ctx)
    end,
}
