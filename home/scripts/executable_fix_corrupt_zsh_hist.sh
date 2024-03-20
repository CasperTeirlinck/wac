#!/usr/bin/env zsh
# Fix a corrupt .zsh_history file without losing all the history.

mv ~/.zsh_history ~/.zsh_history_bad
strings ~/.zsh_history_bad > ~/.zsh_history
fc -R ~/.zsh_history
rm ~/.zsh_history_bad