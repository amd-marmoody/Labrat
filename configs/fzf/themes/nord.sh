# fzf theme: Nord
# https://www.nordtheme.com/
# Full color and style configuration for fzf

# Nord color palette:
# Polar Night:  #2e3440 #3b4252 #434c5e #4c566a
# Snow Storm:   #d8dee9 #e5e9f0 #eceff4
# Frost:        #8fbcbb #88c0d0 #81a1c1 #5e81ac
# Aurora:       #bf616a #d08770 #ebcb8b #a3be8c #b48ead

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#d8dee9,fg+:#eceff4,bg:#2e3440,bg+:#3b4252 \
--color=hl:#ebcb8b,hl+:#d08770,info:#81a1c1,marker:#a3be8c \
--color=prompt:#81a1c1,spinner:#b48ead,pointer:#88c0d0,header:#8fbcbb \
--color=gutter:#2e3440,selected-bg:#434c5e,selected-fg:#eceff4 \
--color=border:#4c566a,separator:#3b4252,scrollbar:#4c566a \
--color=label:#d8dee9,query:#88c0d0 \
--color=preview-fg:#d8dee9,preview-bg:#2e3440 \
--color=preview-border:#4c566a,preview-scrollbar:#4c566a \
--color=preview-label:#d8dee9 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
