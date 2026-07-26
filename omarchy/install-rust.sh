#!/bin/sh

yay -S --noconfirm --needed rustup

# Specifically for non-omarchy systems which didn't install cargo using mise
rustup default stable
