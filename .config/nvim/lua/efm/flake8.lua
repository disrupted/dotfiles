return {
    lintCommand = 'flake8 --stdin-display-name ${INPUT} -',
    lintSource = 'flake8',
    lintStdin = true,
    lintFormats = { '%f:%l:%c: %m' },
}
