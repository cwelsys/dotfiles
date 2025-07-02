#!/bin/bash

set -eufo pipefail

defaults write -g AppleShowAllExtensions -int 1
defaults write -g NSAutomaticCapitalizationEnabled -int 0
defaults write -g NSDocumentSaveNewDocumentsToCloud -int 0
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write com.apple.dock autohide -int 0
# defaults write com.apple.dock orientation -string left
defaults write com.apple.dock show-recents -int 0
defaults write com.apple.finder _FXShowPosixPathInTitle -int 0
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder _FXSortFoldersFirst -int 1
defaults write com.apple.finder FXRemoveOldTrashItems -int 1
defaults write com.apple.finder FXEnableExtensionChangeWarning -int 0
# defaults write -g com.apple.keyboard.fnState -int 1
defaults write -g com.apple.trackpad.forceClick -int 0

launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2>/dev/null
