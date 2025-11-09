## link
https://chatgpt.com/s/t_6910891fdbbc819195dd010f94c7adeb

## body
Here’s exactly what you asked for—first I verify the tag, then I show the CMake knobs you need to build **Clang + LLD + LLDB** and make them the defaults on Pop!_OS 22.04.

# 1) Is `llvmorg-21.1.5` the latest?

Yes. The LLVM homepage and the GitHub “Releases” page show **LLVM 21.1.5** as the current release (announced **Nov 4, 2025**), and the release announcement is on LLVM Discourse. ([LLVM][1])

If you want a shallow checkout of exactly that tag and then a local branch:

```bash
git clone --depth 1 --branch llvmorg-21.1.5 https://github.com/llvm/llvm-project.git
cd llvm-project
git switch -c work-21.1.5   # creates a local branch from the detached HEAD
```

(`--branch` accepts **tags**; with `--depth 1` it checks out the tag in a shallow clone.) ([Git][2])

---

# 2) CMake variables to build Clang, LLD, LLDB (and install as system defaults)

## Minimal, robust configure for the monorepo (Ninja generator)

```bash
cmake -G Ninja -S llvm -B build-21.1.5 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/llvm-21.1.5 \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_ENABLE_ASSERTIONS=ON
```

* `LLVM_ENABLE_PROJECTS` selects **clang / lld / lldb** from the monorepo. ([LLVM][3])
* `CMAKE_INSTALL_PREFIX` is where the toolchain will land (adjust if you prefer `/usr/local/llvm-21`). ([LLVM][3])
* All these options are standard and documented in “Building LLVM with CMake” / “Getting Started.” ([LLVM][4])

Then build & install:

```bash
ninja -C build-21.1.5
sudo ninja -C build-21.1.5 install
```

([LLVM][3])

### Optional, good-to-have toggles

Add any of these to your configure line if they match your goals:

* **Link the LLVM build with lld** (faster/lower RAM while building LLVM itself):

  ```
  -DLLVM_USE_LINKER=lld
  ```

  (This only affects building LLVM; it doesn’t force end-user builds to use lld.) ([LLVM][4])

* **Build libc++/libc++abi/libunwind as runtimes** (if you want a modern C++23 library stack alongside libstdc++):

  ```
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind"
  ```

  (Runtimes are meant to be built with the just-built compiler.) ([LLVM][4])

* **LLDB Python support** (recommended):

  ```
  -DLLDB_ENABLE_PYTHON=ON
  ```

  (LLDB’s build guide discusses Python integration.) ([lldb.llvm.org][5])

### Set driver defaults at build time (optional but nice)

You can bake defaults into the **clang driver** so your day-to-day invocations behave the way you like:

* Default to **lld** as the linker:

  ```
  -DCLANG_DEFAULT_LINKER=lld
  ```

  (Config variable exists in Clang’s CMake; toolchains can honor it.) ([Chromium Git Repositories][6])

* Choose the default **C++ standard library** and **runtime** (if you also build those):

  ```
  -DCLANG_DEFAULT_CXX_STDLIB=libstdc++     # or: libc++
  -DCLANG_DEFAULT_RTLIB=compiler-rt        # or: libgcc
  -DCLANG_DEFAULT_UNWINDLIB=libunwind      # or: libgcc / none
  ```

  (These CMake options are supported by Clang’s build system.) ([Stack Overflow][7])

> Note: even without baking defaults, you can always select the linker per-project with `-fuse-ld=lld`. ([Stack Overflow][8])

---

## Make the new toolchain the **system default** (cleanly reversible)

Use Debian/Ubuntu **update-alternatives** so you don’t overwrite distro files:

```bash
# compilers
sudo update-alternatives --install /usr/bin/clang   clang   /opt/llvm-21.1.5/bin/clang   210
sudo update-alternatives --install /usr/bin/clang++ clang++ /opt/llvm-21.1.5/bin/clang++ 210
sudo update-alternatives --install /usr/bin/clangd  clangd  /opt/llvm-21.1.5/bin/clangd  210

# make 'cc' and 'c++' point to clang as well (optional, but handy for CMake projects)
sudo update-alternatives --install /usr/bin/cc  cc  /opt/llvm-21.1.5/bin/clang   210
sudo update-alternatives --install /usr/bin/c++ c++ /opt/llvm-21.1.5/bin/clang++ 210

# link editor selection:
sudo update-alternatives --install /usr/bin/ld ld /opt/llvm-21.1.5/bin/ld.lld 210
# interactively choose:
sudo update-alternatives --config clang
sudo update-alternatives --config clang++
sudo update-alternatives --config ld
```

* `update-alternatives` is the standard way to switch defaults on Debian/Ubuntu. ([man7.org][9])
* `ld.lld` is a drop-in replacement for GNU `ld` (you can still override per-build with `-fuse-ld=`). ([manpages.debian.org][10])

### Quick sanity checks

```bash
clang++ --version
ld --version      # should report GNU ld (lld) if you selected lld
lldb --version
```

---

## References you can trust

* **LLVM “Building with CMake”** and **Getting Started** (project list, install prefix, typical options). ([LLVM][4])
* **LLDB build guide** (Python, general build notes). ([lldb.llvm.org][5])
* **Clang driver defaults**: `CLANG_DEFAULT_LINKER`, `CLANG_DEFAULT_CXX_STDLIB`, `CLANG_DEFAULT_RTLIB`, `CLANG_DEFAULT_UNWINDLIB`. ([Chromium Git Repositories][6])
* **Using lld** / per-build selection via `-fuse-ld=lld`. ([Stack Overflow][8])
* **Alternatives system** (how to switch defaults cleanly). ([man7.org][9])
* **Release confirmation** for **21.1.5**: LLVM site, GitHub Releases, Discourse announcement. ([LLVM][1])

If you want me to emit a single paste-and-run block that: shallow-clones `llvmorg-21.1.5`, configures with your preferred defaults (e.g., lld as default linker), builds with Ninja, installs to `/opt/llvm-21.1.5`, and registers update-alternatives—say the word and I’ll tailor it.

[1]: https://llvm.org/?utm_source=chatgpt.com "The LLVM Compiler Infrastructure Project"
[2]: https://git-scm.com/docs/git-clone?utm_source=chatgpt.com "Git - git-clone Documentation"
[3]: https://llvm.org/docs/GettingStarted.html?utm_source=chatgpt.com "Getting Started with the LLVM System"
[4]: https://llvm.org/docs/CMake.html?utm_source=chatgpt.com "Building LLVM with CMake — LLVM 22.0.0git documentation"
[5]: https://lldb.llvm.org/resources/build.html?utm_source=chatgpt.com "Building - LLDB - LLVM"
[6]: https://chromium.googlesource.com/external/github.com/llvm-mirror/clang/%2B/refs/heads/google/stable/CMakeLists.txt?utm_source=chatgpt.com "CMakeLists.txt - external/github.com/llvm-mirror/clang"
[7]: https://stackoverflow.com/questions/19901128/enable-libc-libcxx-by-default-when-using-clang?utm_source=chatgpt.com "Enable libc++/libcxx by default when using clang++"
[8]: https://stackoverflow.com/questions/40470931/how-to-specify-an-alternate-linker-command-when-linking-with-cc?utm_source=chatgpt.com "How to specify an alternate linker command when linking ..."
[9]: https://man7.org/linux/man-pages/man1/update-alternatives.1.html?utm_source=chatgpt.com "update-alternatives(1) - Linux manual page"
[10]: https://manpages.debian.org/experimental/lld-18/ld.lld-18.1.en.html?utm_source=chatgpt.com "ld.lld-18(1)"
