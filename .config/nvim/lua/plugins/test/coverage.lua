---@type LazeSpec
return {
    'andythigpen/nvim-coverage',
    main = 'coverage',
    module = 'coverage',
    cmd = {
        'Coverage',
        'CoverageLoad',
        'CoverageLoadLcov',
        'CoverageShow',
        'CoverageHide',
        'CoverageToggle',
        'CoverageClear',
        'CoverageSummary',
    },
    opts = {
        commands = true,
        -- TODO: link existing hl groups
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
    },
}
