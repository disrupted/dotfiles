-- using isortd is a game changer
-- in my testing the formatting on a file went down from 440ms to ~20ms !
return {
    formatCommand = 'curl -s -X POST "localhost:47393" -H "XX-SRC: ${ROOT}" -H "XX-PATH: ${INPUT}" --data-binary @-',
    formatStdin = true,
}
