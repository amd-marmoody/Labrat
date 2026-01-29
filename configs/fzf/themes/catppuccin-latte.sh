# fzf theme: Catppuccin Latte (Light)
# https://github.com/catppuccin/fzf
# Full color and style configuration for fzf

# Catppuccin Latte color palette:
# Base:     #eff1f5  Surface0: #ccd0da  Surface1: #bcc0cc  Surface2: #acb0be
# Text:     #4c4f69  Subtext0: #6c6f85  Subtext1: #5c5f77  Overlay0: #9ca0b0
# Rosewater: #dc8a78  Flamingo: #dd7878  Pink:     #ea76cb  Mauve:    #8839ef
# Red:      #d20f39  Maroon:   #e64553  Peach:    #fe640b  Yellow:   #df8e1d
# Green:    #40a02b  Teal:     #179299  Sky:      #04a5e5  Sapphire: #209fb5
# Blue:     #1e66f5  Lavender: #7287fd

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#4c4f69,fg+:#4c4f69,bg:#eff1f5,bg+:#ccd0da \
--color=hl:#d20f39,hl+:#d20f39,info:#8839ef,marker:#7287fd \
--color=prompt:#8839ef,spinner:#dc8a78,pointer:#dc8a78,header:#d20f39 \
--color=gutter:#eff1f5,selected-bg:#bcc0cc,selected-fg:#4c4f69 \
--color=border:#9ca0b0,separator:#acb0be,scrollbar:#9ca0b0 \
--color=label:#4c4f69,query:#dc8a78 \
--color=preview-fg:#4c4f69,preview-bg:#eff1f5 \
--color=preview-border:#9ca0b0,preview-scrollbar:#9ca0b0 \
--color=preview-label:#4c4f69 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
