#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Auto-start Xfce on TTY1 login
if [[ -z "$DISPLAY" && "$XDG_VTNR" == 1 ]]; then
    exec startxfce4
fi
