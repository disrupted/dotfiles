#!/bin/bash

set -e

path=$(dirname "$1")

while [[ $(realpath "$path") != / ]]; do
    result=$(fd \
        --search-path="$path" \
        --absolute-path \
        --exact-depth=1 \
        --max-results=1 \
        -H -I \
        '^(pyproject\.toml|requirements\.txt|\.git)$')
    if [[ ! -z "$result" ]]; then
        echo $(dirname "$result")
        exit 0
    fi

    path="$(realpath --relative-to="$PWD" "$path"/..)"
done

# fallback 1: git root
git_root=$(git -C "$1" rev-parse --show-toplevel)
if [[ ! -z "$git_root" ]]; then
    echo "$git_root"
    exit 0
fi

# fallback 2: original dir
echo "$1"
exit 1
