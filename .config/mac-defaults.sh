#!/bin/bash

defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 1

defaults write com.apple.screencapture name "screen"
# shellcheck disable=SC2088
defaults write com.apple.screencapture location "~/Pictures/Screenshots"
killall SystemUIServer
