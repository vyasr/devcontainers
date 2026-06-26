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
mkdir -p ${home}/.claude
ln -sf ${dotfiles}/claude-settings.json ${home}/.claude/settings.json

# Global rules: symlink root AGENTS.md to both OpenCode and Claude Code global locations
mkdir -p ${home}/.config/opencode
ln -sf ${claude_files_dir}/devcontainers/root/AGENTS.md ${home}/.config/opencode/AGENTS.md
ln -sf ${claude_files_dir}/devcontainers/root/AGENTS.md ${home}/.claude/CLAUDE.md

# Project-level rules: symlink AGENTS.md into project dirs, with CLAUDE.md compat
for dir in ${home}/*; do
    if [ -d "$dir" ] && [ "$(ls -A $dir)" ]; then
        base_dir=$(basename "$dir")
        agents_md="${claude_files_dir}/devcontainers/${base_dir}/AGENTS.md"
        if [ -f "$agents_md" ]; then
            ln -sf "$agents_md" "${dir}/AGENTS.md"
            ln -sf "AGENTS.md" "${dir}/CLAUDE.md"
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
