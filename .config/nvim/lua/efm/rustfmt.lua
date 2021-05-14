-- not needed with rust_analyzer
return {
    formatCommand = 'rustfmt',
    formatStdin = true,
    lintCommand = 'cargo clippy',
    lintSource = 'cargo',
    lintFormats = { '%f:%l:%c: %m' },
}
