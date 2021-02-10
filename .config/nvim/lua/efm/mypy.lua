return {
    lintCommand = "mypy --show-column-numbers --ignore-missing-imports --config-file=~/.config/mypy/config",
    lintFormats = {
        '%f:%l:%c: %trror: %m', '%f:%l:%c: %tarning: %m', '%f:%l:%c: %tote: %m'
    }
}

