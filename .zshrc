source /home/coder/local/dotfiles/zshrc

# devcontainers install conda at the root and use a slightly nonstandard
# layout, so I would need to patch these functions to work. Fortunately, in
# devcontainers I can always assume conda is installed so I can just disable
# these functions altogether.
unset CONDA_DIR
unset -f _setup_conda
unset -f conda
unset -f mamba

# The below commented out lines are only needed if we want to mimic the default
# behavior of RAPIDS devcontainer prompts. P10k is already doing this for us.
## The next two lines are lifted from oh-my-zsh's lib/theme-and-appearance.zsh
## Sets color variable such as $fg, $bg, $color and $reset_color
#autoload -U colors && colors
#
## Expand variables and commands in PROMPT variables
#setopt prompt_subst
#
#source /home/coder/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
#
## Add the conda environment to the prompt
#export PS1="${CONDA_PROMPT_MODIFIER:-}${PS1}"

# Override the default history file location so that it persists across
# devcontainer restarts or rebuilds. We must do this in zshrc rather than in
# rapids.Dockerfile or similar because we need to override my otherwise default
# setting in the dotfiles zshrc.
export HISTFILE="/home/coder/.cache/._zsh_history"

# Override the default value in the container if an extra proxy was created.
# This proxy is used on remote machines where ssh agent forwarding is used to
# get the SSH agent.
if [[ -S "/tmp/auth_sock/auth_sock" ]]; then
    export SSH_AUTH_SOCK="/tmp/auth_sock/auth_sock"
fi

# Fix where z stores its database to somewhere that persists across
# devcontainer instances.
export ZSHZ_DATA="/home/coder/.cache/zshz_db"
