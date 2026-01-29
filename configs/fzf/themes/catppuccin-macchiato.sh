# fzf theme: Catppuccin Macchiato
# https://github.com/catppuccin/fzf
# Full color and style configuration for fzf

# Catppuccin Macchiato color palette:
# Base:     #24273a  Surface0: #363a4f  Surface1: #494d64  Surface2: #5b6078
# Text:     #cad3f5  Subtext0: #a5adcb  Subtext1: #b8c0e0  Overlay0: #6e738d
# Rosewater: #f4dbd6  Flamingo: #f0c6c6  Pink:     #f5bde6  Mauve:    #c6a0f6
# Red:      #ed8796  Maroon:   #ee99a0  Peach:    #f5a97f  Yellow:   #eed49f
# Green:    #a6da95  Teal:     #8bd5ca  Sky:      #91d7e3  Sapphire: #7dc4e4
# Blue:     #8aadf4  Lavender: #b7bdf8

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#cad3f5,fg+:#cad3f5,bg:#24273a,bg+:#363a4f \
--color=hl:#ed8796,hl+:#ed8796,info:#c6a0f6,marker:#b7bdf8 \
--color=prompt:#c6a0f6,spinner:#f4dbd6,pointer:#f4dbd6,header:#ed8796 \
--color=gutter:#24273a,selected-bg:#494d64,selected-fg:#cad3f5 \
--color=border:#6e738d,separator:#5b6078,scrollbar:#6e738d \
--color=label:#cad3f5,query:#f4dbd6 \
--color=preview-fg:#cad3f5,preview-bg:#24273a \
--color=preview-border:#6e738d,preview-scrollbar:#6e738d \
--color=preview-label:#cad3f5 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
