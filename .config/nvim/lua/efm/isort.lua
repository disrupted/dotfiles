return {
    formatCommand = 'cd "${ROOT}"; isort --profile black --quiet --stdout -',
    -- formatCommand = 'isort --profile black --quiet --stdout --src-path "${ROOT}" -', -- experimental, might need to provide filepath
    formatStdin = true,
}
