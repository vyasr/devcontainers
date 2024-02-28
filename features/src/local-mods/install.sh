#! /usr/bin/env bash
set -e

# We need to symlink to the files in dotfiles rather than directly mounting the
# corresponding symlinks from the host machine so that we don't copy the files
# and lose the ability to update them consistently in both the host machine and
# the container. type=bind,consistency=consistent is not sufficient for symlinks
home="/home/coder"
dotfiles="${home}/local/dotfiles"
claude_files_dir="${home}/local/claude_files"
ln -s ${dotfiles}/git_aliases ${home}/.git_aliases
ln -s ${dotfiles}/gitignore ${home}/.gitignore
ln -s ${dotfiles}/inputrc ${home}/.inputrc
ln -s ${dotfiles}/vimrc ${home}/.vimrc
mkdir -p ${home}/.config/nvim
ln -s ${dotfiles}/init.lua ${home}/.config/nvim/init.lua
ln -s ${claude_files_dir}/devcontainers/root/CLAUDE.md ${home}/CLAUDE.md
# Loop over directories ${dir} in ${home} and check if they are nonempty. If so, see if a corresponding directory exists in ${claude_files_dir}/devcontainers/${dir}. If there is one and it has a CLAUDE.md file, symlink that file into the ${home} directory as ${dir}/CLAUDE.md
for dir in ${home}/*; do
    if [ -d "$dir" ] && [ "$(ls -A $dir)" ]; then
        base_dir=$(basename "$dir")
        claude_md="${claude_files_dir}/devcontainers/${base_dir}/CLAUDE.md"
        if [ -f "$claude_md" ]; then
            ln -s "$claude_md" "${dir}/CLAUDE.md"
        fi
    fi
done

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
