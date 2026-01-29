# fzf theme: Gruvbox Light
# https://github.com/morhetz/gruvbox
# Full color and style configuration for fzf

# Gruvbox Light color palette:
# bg:       #fbf1c7  bg1:      #ebdbb2  bg2:      #d5c4a1  bg3:      #bdae93
# fg:       #3c3836  fg1:      #282828  gray:     #928374
# red:      #cc241d  green:    #98971a  yellow:   #d79921  blue:     #458588
# purple:   #b16286  aqua:     #689d6a  orange:   #d65d0e

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#3c3836,fg+:#282828,bg:#fbf1c7,bg+:#ebdbb2 \
--color=hl:#d79921,hl+:#d65d0e,info:#458588,marker:#98971a \
--color=prompt:#cc241d,spinner:#b16286,pointer:#b16286,header:#689d6a \
--color=gutter:#fbf1c7,selected-bg:#d5c4a1,selected-fg:#282828 \
--color=border:#bdae93,separator:#d5c4a1,scrollbar:#bdae93 \
--color=label:#3c3836,query:#d65d0e \
--color=preview-fg:#3c3836,preview-bg:#fbf1c7 \
--color=preview-border:#bdae93,preview-scrollbar:#bdae93 \
--color=preview-label:#3c3836 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
