local M = {}

function M.setup()
    --
end

function M.config()
    require('coverage').setup {
        commands = true,
        -- create highlight groups
        -- TODO: link existing ones
        highlights = {
            covered = { fg = '#C3E88D' },
            uncovered = { fg = '#F07178' },
        },
        signs = {
            covered = { hl = 'CoverageCovered', text = '▎' },
            uncovered = { hl = 'CoverageUncovered', text = '▎' },
        },
        summary = {
            min_coverage = 80.0,
        },
    }
end

return M
