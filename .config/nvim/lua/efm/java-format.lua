return {
    formatCommand = 'java -jar '
        .. os.getenv 'HOME'
        .. '/.local/jars/google-java-format.jar'
        .. vim.api.nvim_buf_get_name(0),
    formatStdin = true,
}
