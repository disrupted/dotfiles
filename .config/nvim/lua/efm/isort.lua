-- return {formatCommand = "isort --stdout --profile black -", formatStdin = true}
return {
    formatCommand = "isort --quiet --stdout --sp backend/.isort.cfg --lines-between-types=1 -",
    formatStdin = true
}
