return {
    -- formatCommand = "isort --quiet --stdout --sp backend/.isort.cfg --lines-between-types=1 -",
    formatCommand = "isort --quiet --stdout --profile black -",
    formatStdin = true
}
