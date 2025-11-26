#!/bin/bash

defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 1

defaults write -g NSWindowShouldDragOnGesture YES

defaults write com.apple.screencapture name "screen"
# shellcheck disable=SC2088
defaults write com.apple.screencapture location "~/Pictures/Screenshots"
killall SystemUIServer

# disable universal clipboard between iCloud devices while keeping Handoff turned on
# requires full disk access for terminal app
defaults write ~/Library/Preferences/com.apple.coreservices.useractivityd.plist ClipboardSharingEnabled 0
