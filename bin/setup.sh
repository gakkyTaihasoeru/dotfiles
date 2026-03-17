#!/bin/bash

# 拡張子を常に表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# ダークモード
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Fnキーを標準のファンクションキーとして使用
defaults write NSGlobalDomain "com.apple.keyboard.fnState" -bool true

# 文頭の自動大文字化を無効
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# 設定を反映させるためにFinderとSystemUIServerを再起動
killall Finder
