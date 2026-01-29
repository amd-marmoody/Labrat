# fzf theme: Dracula
# https://draculatheme.com/
# Full color and style configuration for fzf

# Dracula color palette:
# Background: #282a36  Current Line: #44475a  Selection: #44475a  Foreground: #f8f8f2
# Comment:    #6272a4  Cyan:         #8be9fd  Green:     #50fa7b  Orange:     #ffb86c
# Pink:       #ff79c6  Purple:       #bd93f9  Red:       #ff5555  Yellow:     #f1fa8c

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=fg:#f8f8f2,fg+:#f8f8f2,bg:#282a36,bg+:#44475a \
--color=hl:#ffb86c,hl+:#ffb86c,info:#bd93f9,marker:#50fa7b \
--color=prompt:#ff79c6,spinner:#8be9fd,pointer:#8be9fd,header:#bd93f9 \
--color=gutter:#282a36,selected-bg:#44475a,selected-fg:#f8f8f2 \
--color=border:#6272a4,separator:#44475a,scrollbar:#6272a4 \
--color=label:#f8f8f2,query:#8be9fd \
--color=preview-fg:#f8f8f2,preview-bg:#282a36 \
--color=preview-border:#6272a4,preview-scrollbar:#6272a4 \
--color=preview-label:#f8f8f2 \
--border='rounded' --border-label='' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' --separator='─' --scrollbar='│'"
