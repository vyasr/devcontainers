#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python-editable [OPTION]...
#
# Build ${PY_LIB} in editable mode.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;
# @_include_pip_install_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${PY_LIB}_python_editable() {
    # Initialize runtime variable from template-substituted value
    local py_src="${PY_SRC}";

    # Adjust py_src if running from a git worktree
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # Get the actual worktree root (current working directory's git root)
        local worktree_root="$(git rev-parse --show-toplevel)"

        # Calculate relative path from SRC_PATH to py_src
        # Example: SRC_PATH=~/rmm, py_src=~/rmm/python/librmm -> relative=python/librmm
        local relative_path="${py_src#${SRC_PATH}}"
        relative_path="${relative_path#/}"  # Remove leading slash if present

        # Check if cwd's worktree root differs from SRC_PATH
        # If different, we're in a worktree and need to adjust py_src
        if [[ "${worktree_root}" != "${SRC_PATH}" ]]; then
            # Verify both paths are in the same repository by comparing git common dirs
            local src_git_common_dir="$(git -C "${SRC_PATH}" rev-parse --git-common-dir 2>/dev/null || true)"
            local worktree_git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null || true)"

            # Only adjust py_src if we can verify both are from the same repository
            if [[ -n "${src_git_common_dir}" ]] && [[ -n "${worktree_git_common_dir}" ]]; then
                # Resolve to absolute paths for comparison
                src_git_common_dir="$(cd "${SRC_PATH}" && cd "${src_git_common_dir}" && pwd)"
                worktree_git_common_dir="$(cd "${worktree_git_common_dir}" && pwd)"

                # Only adjust py_src if worktree is from the same repository
                if [[ "${src_git_common_dir}" == "${worktree_git_common_dir}" ]]; then
                    py_src="${worktree_root}/${relative_path}"
                fi
            fi
        fi
    fi

    install-${PY_LIB}-python --no-build-isolation --no-deps --editable "${py_src}" "$@" <&0;
}

build_${PY_LIB}_python_editable "$@" <&0;
