# fzf theme: Gruvbox Dark
# https://github.com/morhetz/gruvbox
# Full color and style configuration for fzf

# Gruvbox Dark color palette:
# bg:       #282828  bg1:      #3c3836  bg2:      #504945  bg3:      #665c54
# fg:       #ebdbb2  fg1:      #fbf1c7  gray:     #928374  
# red:      #fb4934  green:    #b8bb26  yellow:   #fabd2f  blue:     #83a598
# purple:   #d3869b  aqua:     #8ec07c  orange:   #fe8019

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#ebdbb2,fg+:#fbf1c7,bg:#282828,bg+:#3c3836 \
--color=hl:#fabd2f,hl+:#fe8019,info:#83a598,marker:#b8bb26 \
--color=prompt:#fb4934,spinner:#d3869b,pointer:#d3869b,header:#8ec07c \
--color=gutter:#282828,selected-bg:#504945,selected-fg:#fbf1c7 \
--color=border:#665c54,separator:#504945,scrollbar:#665c54 \
--color=label:#ebdbb2,query:#fe8019 \
--color=preview-fg:#ebdbb2,preview-bg:#282828 \
--color=preview-border:#665c54,preview-scrollbar:#665c54 \
--color=preview-label:#ebdbb2 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
