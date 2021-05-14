return {
    lintCommand = 'shellcheck -f gcc -x',
    lintSource = 'shellcheck',
    lintFormats = {
        '%f:%l:%c: %trror: %m',
        '%f:%l:%c: %tarning: %m',
        '%f:%l:%c: %tote: %m',
    },
}
