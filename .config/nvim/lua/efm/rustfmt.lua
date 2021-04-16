-- not needed with rust_analyzer
return {
    formatCommand = "rustfmt",
    formatStdin = true,
    lintCommand = "cargo clippy",
    lintFormats = {"%f:%l:%c: %m"}
}
