#!/bin/bash

pacman -Slq | fzf -m --preview 'pacman -Si {}' | xargs -ro sudo pacman -S
