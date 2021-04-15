#!/bin/bash

set -e

path=$(dirname "$1")

while [[ $(realpath "$path") != / ]]; do
    result=$(fd \
        --search-path="$path" \
        --absolute-path \
        --exact-depth=1 \
        --max-results=1 \
        -H -I -g \
        "pyproject.toml")
    if [[ ! -z "$result" ]]; then
        echo $(dirname "$result")
        exit 0
    fi

    path="$(realpath --relative-to="$PWD" "$path"/..)"
done
echo $(git -C "$1" rev-parse --show-toplevel)  # fallback 1: git root
# echo "$1"                                    # fallback 2: original dir
exit 1
