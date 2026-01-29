# fzf theme: Catppuccin Frappe
# https://github.com/catppuccin/fzf
# Full color and style configuration for fzf

# Catppuccin Frappe color palette:
# Base:     #303446  Surface0: #414559  Surface1: #51576d  Surface2: #626880
# Text:     #c6d0f5  Subtext0: #a5adce  Subtext1: #b5bfe2  Overlay0: #737994
# Rosewater: #f2d5cf  Flamingo: #eebebe  Pink:     #f4b8e4  Mauve:    #ca9ee6
# Red:      #e78284  Maroon:   #ea999c  Peach:    #ef9f76  Yellow:   #e5c890
# Green:    #a6d189  Teal:     #81c8be  Sky:      #99d1db  Sapphire: #85c1dc
# Blue:     #8caaee  Lavender: #babbf1

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#c6d0f5,fg+:#c6d0f5,bg:#303446,bg+:#414559 \
--color=hl:#e78284,hl+:#e78284,info:#ca9ee6,marker:#babbf1 \
--color=prompt:#ca9ee6,spinner:#f2d5cf,pointer:#f2d5cf,header:#e78284 \
--color=gutter:#303446,selected-bg:#51576d,selected-fg:#c6d0f5 \
--color=border:#737994,separator:#626880,scrollbar:#737994 \
--color=label:#c6d0f5,query:#f2d5cf \
--color=preview-fg:#c6d0f5,preview-bg:#303446 \
--color=preview-border:#737994,preview-scrollbar:#737994 \
--color=preview-label:#c6d0f5 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
