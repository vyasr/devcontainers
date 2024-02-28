#! /usr/bin/env bash
# This init script creates files needed at the root devcontainers dir

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

echo ${PWD}
for dir in .vim .local .cache local; do
    mkdir ../../../../${dir}
done

# Also copy over fzf files since we mount them
cp ~/.fzf.* ../../../../
