# fzf theme: Tokyo Night
# https://github.com/folke/tokyonight.nvim
# Full color and style configuration for fzf

# Tokyo Night color palette:
# bg:       #1a1b26  bg_dark:  #16161e  bg_hl:    #292e42  terminal_black: #414868
# fg:       #c0caf5  fg_dark:  #a9b1d6  fg_gutter:#3b4261  comment:  #565f89
# blue:     #7aa2f7  cyan:     #7dcfff  green:    #9ece6a  magenta:  #bb9af7
# orange:   #ff9e64  red:      #f7768e  yellow:   #e0af68  teal:     #1abc9c

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#c0caf5,fg+:#c0caf5,bg:#1a1b26,bg+:#292e42 \
--color=hl:#ff9e64,hl+:#ff9e64,info:#bb9af7,marker:#9ece6a \
--color=prompt:#7aa2f7,spinner:#7dcfff,pointer:#7dcfff,header:#7aa2f7 \
--color=gutter:#1a1b26,selected-bg:#414868,selected-fg:#c0caf5 \
--color=border:#3b4261,separator:#292e42,scrollbar:#3b4261 \
--color=label:#c0caf5,query:#7dcfff \
--color=preview-fg:#c0caf5,preview-bg:#1a1b26 \
--color=preview-border:#3b4261,preview-scrollbar:#3b4261 \
--color=preview-label:#c0caf5 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
