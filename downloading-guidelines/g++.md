# g++ (GNU C++ Compiler) — Downloading Guideline

MinGW-w64 homepage: https://www.mingw-w64.org/  
MSYS2 installer: https://www.msys2.org/

## Option A: Ubuntu / Debian (Recommended)

```bash
sudo apt update
sudo apt install -y build-essential gdb
# build-essential includes: g++, gcc, make, libc6-dev

g++ --version
gcc --version
gdb --version
```

Expected (Ubuntu 24.04): `g++ (Ubuntu 13.3.0-...)`.

Test compile:
```bash
echo '#include <bits/stdc++.h>
using namespace std;
int main(){ cout << "g++ works\n"; }' > hello.cpp
g++ -std=c++17 -O2 -Wall hello.cpp -o hello && ./hello
```

## Option B: Windows 10/11 — MSYS2 UCRT64 (Recommended)

1. Download + install **MSYS2 x86_64** from https://www.msys2.org/
2. Open **MSYS2 UCRT64** terminal (not plain MSYS), run:
   ```bash
   pacman -Syu
   # reopen terminal if asked, then:
   pacman -S --needed base-devel mingw-w64-ucrt-x86_64-toolchain
   ```
3. Add to PATH: `C:\msys64\ucrt64\bin`
   (Search "Edit environment variables" → Path → New → paste → OK → reopen terminal/VS Code).
4. Verify in **PowerShell / CMD**:
   ```powershell
   g++ --version
   gdb --version
   ```

Alternative: WinLibs standalone builds from https://winlibs.com/ (download `winlibs-x86_64-posix-seh-gcc-*.zip`, extract, add `mingw64\bin` to PATH).

## Option C: Windows — Code::Blocks bundled MinGW

If you installed `codeblocks-XX.XXmingw-setup.exe`, you already have g++ under e.g. `C:\Program Files\CodeBlocks\MinGW\bin`. Add that folder to PATH to use `g++` in terminal/VS Code.

## Useful versions / flags

```bash
g++ --version
g++ -std=c++17 -O2 -Wall -Wextra file.cpp -o file
./file
```

For competitive programming add `-static` only if the judge requires it; locally prefer dynamic for speed.
