#!/usr/bin/env bash

# Usage:
#  clean-${PY_LIB}-python [OPTION]...
#
# Clean the ${PY_LIB} build dirs.
#
# Boolean options:
#  -h,--help  Print this text.

# shellcheck disable=SC1091
. rapids-generate-docstring;

clean_${PY_LIB}_python() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

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
            py_src="${worktree_root}/${relative_path}"
        fi
    fi

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all clean-${NAME} clean-${PY_LIB}-python';

    if [[ ! -d "${py_src}" ]]; then
        return;
    fi

    local py_lib="${PY_LIB}";

    rm -rf -- \
        "${py_src}"/_skbuild \
        "${py_src}/${BIN_DIR}"/{*,.*} \
        "${py_src}"/{${py_lib},${py_lib//"-"/"_"}}.egg-info \
        2>/dev/null || true;

    for lib in "${py_lib}" "${py_lib//"-"/"_"}"; do
        if test -d "${py_src}/${lib}/"; then
            find "${py_src}/${lib}/" -type f \
                -iname "*.cpython-*-$(uname -m)-$(uname -s)-*.so" \
                -delete;
        fi
    done

    local py_ver="${PYTHON_VERSION:-$("${ORIG_PYTHON:-python3}" --version 2>&1 | cut -d' ' -f2)}";
    py_ver="$(grep -Po '^[0-9]+\.[0-9]+' <<< "${py_ver}")";

    if test -d "${py_src}/build"; then
        local slug="$(uname -s)-$(uname -m)";
        rm -rf --                                                                                   \
            `# scikit-buld-core build dirs`                                                         \
            "${py_src}"/build/cp{${py_ver},${py_ver/./}}-cp{${py_ver},${py_ver/./}}*                \
            `# setuptools/distutils build dirs`                                                     \
            "${py_src}"/build/{lib,temp,dist,bdist}.${slug,,}                                       \
            "${py_src}"/build/{lib,temp,dist,bdist}.${slug,,}-{,cpython}{,-}{${py_ver},${py_ver/./}};
    fi

    uninstall-${PY_LIB}-python "@" || true;
}

clean_${PY_LIB}_python "$@" <&0;
