# Code::Blocks — Downloading Guideline

Official site: https://www.codeblocks.org/  
Binaries page: https://www.codeblocks.org/downloads/binaries/

## Option A: Ubuntu / Debian (Recommended)

```bash
sudo apt update
sudo apt install -y codeblocks codeblocks-contrib
codeblocks --version
```

Launch: Activities → search "CodeBlocks", or `codeblocks &`.

> Ubuntu 24.04 ships Code::Blocks 20.03. g++ must be installed separately (see [g++.md](./g++.md)).

## Option B: Windows 10/11

1. Go to https://www.codeblocks.org/downloads/binaries/
2. Under **Windows**, download the file with `mingw-setup` in the name, e.g.:
   `codeblocks-20.03mingw-setup.exe` (~100+ MB, includes bundled GCC).
   - Use a mirror like Sourceforge if the main link is slow.
3. Run the `.exe` → Next → Full install → Finish.
4. First launch: it auto-detects `GNU GCC Compiler`. Click **Set as default** → OK.
5. Test: File → New → Empty file → write Hello World → Save as `test.cpp` → Build & Run (F9).

## Verify

- Open Code::Blocks → Settings → Compiler → Toolchain executables → should show `g++`, `gcc`, `gdb`.
- Build & Run a test file, output appears in bottom log pane.

## Troubleshooting

- **"No compiler found"**: install g++ (`sudo apt install build-essential` on Ubuntu, or reinstall the `mingw-setup` variant on Windows).
- **Debugger missing**: `sudo apt install gdb`, then Settings → Debugger → Default → path `/usr/bin/gdb`.
