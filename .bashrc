#
# ~/.bashrc
#
# If not running interactively, don't do anything
[[ $- != *i* ]] && return


PS1='\[\e[37m\][\[\e[m\]\[\e[1;32m\]\D{%I:%M%P}\[\e[m\]@\[\e[1;35m\]\h\[\e[m\]\[\e[37m\]]\[\e[m\] \[\033[01;34m\]\w\[\e[m\]\n\[\e[37m\]↳\[\e[m\]\[\033[01;33m\]\u\[\e[m\]\[\e[1;31m\]\\$\[\e[m\] '

alias ls='ls --color=auto'
alias ll='ls -lav --ignore=..' # show long listing of all except ".."
alias l='ls -lav --ignore=.?*' # show long listing but no hidden dotfiles except "."

[[ "$(whoami)" = "root" ]] && return

[[ -z "$FUNCNEST" ]] && export FUNCNEST=100 # limits recursive functions, see 'man bash'

## Use the up and down arrow keys for finding a command in history
## (you can write some initial letters of the command first).
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

_open_files_for_editing () {
    # Open any given document file(s) for editing (or just viewing).
    # Note1:
    #    - Do not use for executable files!
    # Note2:
    #    - Uses 'mime' bindings, so you may need to use
    #      e.g. a file manager to make proper file bindings.

    if [ -x /usr/bin/exo-open ]; then
        echo "exo-open" "$@" >&2
        setsid exo-open "$@" >&/dev/null
        return
    fi
    if [ -x /usr/bin/xdg-open ]; then
        for file in "$@"; do
            echo "xdg-open $file" >&2
            setsid xdg-open "$file" >&/dev/null
        done
        return
    fi

    echo "$FUNCNAME: package 'xdg-utils' or 'exo' is required." >&2
}

alias ef='_open_files_for_editing' # 'ef' opens given file(s) for editing
#------------------------------------------------------------

[[ -f ~/.aliases.bashrc ]] && source ~/.aliases.bashrc
[[ -f ~/.ffmpeg.bashrc ]] && source ~/.ffmpeg.bashrc
[[ -f ~/.funcs.bashrc ]] && source ~/.funcs.bashrc
[[ -f /etc/profile.d/bash_completion.sh ]] && source /etc/profile.d/bash_completion.sh
for f in ~/.bash_completion.d/*; do
    source "$f"
done
#------------------------------------------------------------

#XDG_DATA_DIRS=$XDG_DATA_DIRS\
#:$HOME/.local/share/flatpak/exports/share

export EDITOR=/usr/bin/nvim
export PATH=$PATH:~/.local/bin\
:~/.cargo/bin/\
:$HOME/.platformio/packages/toolchain-atmelavr/bin/\
:$HOME/.platformio/penv/bin\
:/home/misc/bin/android-studio/bin/\
:/home/misc/bin/android-sdk/cmdline-tools/latest/bin/\
:/home/misc/bin/android-sdk/emulator/

export CHROME_EXECUTABLE=/usr/bin/chromium-browser

HISTIGNORE="cd *"
export HISTSIZE=50000
export HISTFILESIZE=200000
export HISTCONTROL=erasedups:ignoredups
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

shopt -s checkwinsize

#------------------------------------------------------------

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH
export GPG_TTY=$(tty)

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/bash/__tabtab.bash ] && {
    . ~/.config/tabtab/bash/__tabtab.bash || true
} # end bun

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# pyenv
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env

. "$HOME/.cargo/env"
