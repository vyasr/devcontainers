#! /usr/bin/env bash
set -e

home="/home/coder"
ln -s ${home}/local/dotfiles/git_aliases ${home}/.git_aliases
ln -s ${home}/local/dotfiles/gitignore ${home}/.gitignore
ln -s ${home}/local/dotfiles/inputrc ${home}/.inputrc
ln -s ${home}/local/dotfiles/vimrc ${home}/.vimrc

# We make a modified copy of zshrc that sources the dotfiles one inside the
# container instead of linking it so that we can include devcontainer-specific
# modifications.
#ln -s ${home}/local/dotfiles/zshrc ${home}/.vimrc

# These links cannot be created this way because the .vim mount is not yet
# available when install.sh is run, so instead I manually create the links on
# the host system since the targets don't have to be valid to create the links.
# see https://github.com/devcontainers/spec/issues/434
#ln -s ${home}/local/dotfiles/coc-settings.json ${home}/.vim/coc-settings.json
#ln -s ${home}/local/dotfiles/UltiSnips ${home}/.vim/UltiSnips
