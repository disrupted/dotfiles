return {
    lintCommand = './node_modules/.bin/eslint -f visualstudio --stdin --stdin-filename ${INPUT}',
    lintSource = 'eslint',
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = { '%f(%l,%c): %tarning %m', '%f(%l,%c): %rror %m' },
}
