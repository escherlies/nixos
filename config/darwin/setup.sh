#!/bin/bash

# Disable mouse acc
defaults write .GlobalPreferences com.apple.mouse.scaling -1

# Symlink hammerspooon
ln -s $PWD/hammerspoon.lua $HOME/.hammerspoon/init.lua

# Symlink home.nix
ln -s $PWD/home.nix $HOME/.config/home-manager/home.nix
