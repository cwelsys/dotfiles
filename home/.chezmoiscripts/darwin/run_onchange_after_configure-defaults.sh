#!/bin/bash

set -eufo pipefail

defaults write -g AppleShowAllExtensions -int 1
defaults write -g NSAutomaticCapitalizationEnabled -int 0
defaults write -g NSDocumentSaveNewDocumentsToCloud -int 0
defaults write com.apple.dock autohide -int 1
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock show-recents -int 0
defaults write com.apple.finder _FXShowPosixPathInTitle -int 1
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder _FXSortFoldersFirst -int 1
defaults write com.apple.finder FXRemoveOldTrashItems -int 1
defaults write com.apple.finder FXEnableExtensionChangeWarning -int 0
