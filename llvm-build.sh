#!/bin/sh

# https://chatgpt.com/s/t_6910891fdbbc819195dd010f94c7adeb

# 1. configure
cmake -G Ninja -S llvm -B build-21.1.5 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/llvm-21.1.5 \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_ENABLE_ASSERTIONS=ON

# 2. build
ninja -C build-21.1.5

# 3. install
sudo ninja -C build-21.1.5 install

