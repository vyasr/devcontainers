#!/usr/bin/env bash

# Usage:
#  build-${PY_LIB}-python-wheel [OPTION]...
#
# Build a ${PY_LIB} wheel.
#
# @_include_value_options rapids-get-num-archs-jobs-and-load -h;
# @_include_cmake_options;
# CMake Install Options:
#  --strip  Strip before installing.
#
# @_include_pip_wheel_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

build_${PY_LIB}_python_wheel() {
    local -;
    set -euo pipefail;

    eval "$(                                          \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc --all)}  \
        rapids-get-num-archs-jobs-and-load "$@"       \
        2>/dev/null                                   \
    )";

    local py_lib="${PY_LIB}";

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

    local -a cmake_args_="(${CMAKE_ARGS:-})";
    cmake_args_+=(${CPP_CMAKE_ARGS});

    local -a pip_args_=(${PIP_WHEEL_ARGS});

    eval "$(_parse_args --take '-G -v,--verbose' "$@" "${cmake_args_[@]}" "${pip_args_[@]}" <&0)";

    if [[ ! -d "${py_src}" ]]; then
        echo "build-${PY_LIB}-python-wheel: cannot access '${py_src}': No such directory" >&2;
        exit 1;
    fi

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'build-all build-${NAME} build-${PY_LIB}-python build-${PY_LIB}-python-wheel';

    local -a cmake_args="(
        -G\"${G:-Ninja}\"
        ${cmake_args_[*]@Q}
        ${CPP_DEPS}
        ${v:+--log-level=VERBOSE}
        $(rapids-select-cmake-args "$@")
    )";

    local ninja_args=();

    if test -n "${v:+x}"; then
        ninja_args+=("-v");
    fi

    if test -n "${n_jobs:+x}"; then
        ninja_args+=("-j${n_jobs}");
    fi

    local -a pip_args="(
        ${pip_args_+"${pip_args_[*]@Q}"}
        $(rapids-select-pip-wheel-args "$@")
    )";

    if rapids-python-uses-scikit-build "${py_src}"; then
        # Clean the `_skbuild/.../cmake-build` dir if configuration failed before
        if ! test -d "$(rapids-maybe-clean-build-dir "${cmake_args[@]}" -- "${py_src}")"; then
            rm -rf "${py_src}/_skbuild";
        fi
    elif rapids-python-uses-scikit-build-core "${py_src}"; then
        pip_args+=(-C "build-dir=$(rapids-maybe-clean-build-dir "${cmake_args[@]}" -- "${py_src}")");
    fi

    pip_args+=("${py_src}");

    # Ensure SCCACHE_NO_DIST_COMPILE=1 is set while configuring
    # so CMake's compiler tests never use the build cluster.

    if ! test -f /tmp/sccache_no_dist_compile.cmake; then
        cat <<"EOF" > /tmp/sccache_no_dist_compile.cmake
set(ENV{SCCACHE_NO_DIST_COMPILE} "1")
EOF
    fi

    # Merge with outer `-DCMAKE_PROJECT_INCLUDE_BEFORE=` if provided
    local -a cmake_project_include_before="(
        $(rapids-select-cmake-define CMAKE_PROJECT_INCLUDE_BEFORE "$@" || echo)
        /tmp/sccache_no_dist_compile.cmake
    )";
    # Join with semicolons
    cmake_args+=("-DCMAKE_PROJECT_INCLUDE_BEFORE=$(IFS=";"; echo "${cmake_project_include_before[*]}")")

    trap "rm -rf '${py_src}/${py_lib//"-"/"_"}.egg-info'" EXIT;

    time (
        echo "Building ${PY_LIB} wheel";
        export ${PY_ENV} PATH="$PATH";
        local cudaflags="${CUDAFLAGS:+$CUDAFLAGS }-t=${n_arch}";
        local build_type="$(rapids-select-cmake-build-type "${cmake_args[@]}" || echo "Release")";
        local nvcc_append_flags="${NVCC_APPEND_FLAGS:+$NVCC_APPEND_FLAGS }-t=${n_arch}";

        CUDAFLAGS="${cudaflags}"                     \
        CMAKE_GENERATOR="${G:-Ninja}"                \
        PARALLEL_LEVEL="${n_jobs}"                   \
        CMAKE_ARGS="${cmake_args[*]@Q}"              \
        SKBUILD_BUILD_OPTIONS="${ninja_args[*]}"     \
        SKBUILD_BUILD_VERBOSE="${v:+True}"           \
        SKBUILD_LOGGING_LEVEL="${v:+INFO}"           \
        SKBUILD_INSTALL_STRIP="${strip:+True}"       \
        SKBUILD_CMAKE_BUILD_TYPE="${build_type}"     \
        CMAKE_BUILD_PARALLEL_LEVEL="${n_jobs}"       \
        NVCC_APPEND_FLAGS="${nvcc_append_flags}"     \
            python -m pip wheel "${pip_args[@]}" 2>&1;
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} wheel build time:";
    ) 2> >(tee -a /var/log/devcontainer-utils/install-${PY_LIB}-python-time.log >&2);
}

build_${PY_LIB}_python_wheel "$@" <&0;
