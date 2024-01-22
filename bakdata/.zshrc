function kubeconfig-select {
    local base_path=~/.kube/projects
    local fzf_preview="bat --style=numbers --color=always --wrap never -l yaml $base_path/{}/config"
    local fzf_arguments=(--multi --ansi $fzf_dir_opts --prompt="kubeconfig> " --preview="$fzf_preview")

    local fd_args=(config $base_path
        -d 2 # don't recurse deeper
    )
    local configs=$(fd $fd_args | xargs dirname | xargs basename)

    local config=$(echo $configs | fzf $fzf_arguments | paste -sd: -)

    # nothing selected, quit
    if  test -z "$config"; then
        return 1
    fi

    export KUBECONFIG=$base_path/$config/config
    echo "Updated KUBECONFIG to $KUBECONFIG"
}
