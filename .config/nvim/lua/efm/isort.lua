return {
    formatCommand = "cd $(~/.config/scripts/fd_project_root.sh \"${INPUT}\"); isort --profile black --quiet --stdout -",
    formatStdin = true
}
