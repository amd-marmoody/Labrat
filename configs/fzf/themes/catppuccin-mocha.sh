# fzf theme: Catppuccin Mocha
# https://github.com/catppuccin/fzf
# Full color and style configuration for fzf

# Catppuccin Mocha color palette:
# Base:     #1e1e2e  Surface0: #313244  Surface1: #45475a  Surface2: #585b70
# Text:     #cdd6f4  Subtext0: #a6adc8  Subtext1: #bac2de  Overlay0: #6c7086
# Rosewater: #f5e0dc  Flamingo: #f2cdcd  Pink:     #f5c2e7  Mauve:    #cba6f7
# Red:      #f38ba8  Maroon:   #eba0ac  Peach:    #fab387  Yellow:   #f9e2af
# Green:    #a6e3a1  Teal:     #94e2d5  Sky:      #89dceb  Sapphire: #74c7ec
# Blue:     #89b4fa  Lavender: #b4befe

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#cdd6f4,fg+:#cdd6f4,bg:#1e1e2e,bg+:#313244 \
--color=hl:#f38ba8,hl+:#f38ba8,info:#cba6f7,marker:#b4befe \
--color=prompt:#cba6f7,spinner:#f5e0dc,pointer:#f5e0dc,header:#f38ba8 \
--color=gutter:#1e1e2e,selected-bg:#45475a,selected-fg:#cdd6f4 \
--color=border:#6c7086,separator:#585b70,scrollbar:#6c7086 \
--color=label:#cdd6f4,query:#f5e0dc \
--color=preview-fg:#cdd6f4,preview-bg:#1e1e2e \
--color=preview-border:#6c7086,preview-scrollbar:#6c7086 \
--color=preview-label:#cdd6f4 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
