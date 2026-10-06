# Downloading & Installation Guidelines

Step-by-step guides to download and install essential programming tools for C/C++ development:

| Tool | Guide | Official Download |
|------|-------|-------------------|
| Code::Blocks | [codeblocks.md](./codeblocks.md) | https://www.codeblocks.org/downloads/binaries/ |
| Sublime Text | [sublime-text.md](./sublime-text.md) | https://www.sublimetext.com/download |
| VS Code | [vscode.md](./vscode.md) | https://code.visualstudio.com/download |
| g++ (GNU C++ Compiler) | [g++.md](./g++.md) | Ubuntu: `build-essential` / Windows: https://www.mingw-w64.org/ |

## Quick Setup (Ubuntu 24.04)

```bash
# g++ + build tools
sudo apt update
sudo apt install -y build-essential gdb
g++ --version

# VS Code (snap or apt)
sudo snap install --classic code
# or download .deb from the site above, then:
# sudo apt install ./code_*.deb

# Code::Blocks
sudo apt update
sudo apt install -y codeblocks codeblocks-contrib

# Sublime Text (official repo)
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update
sudo apt install -y sublime-text
```

## Quick Setup (Windows 10/11)

1. **g++**: Install MSYS2 from https://www.msys2.org/ , then in MSYS2 terminal: `pacman -S --needed base-devel mingw-w64-ucrt-x86_64-toolchain`. Add `C:\msys64\ucrt64\bin` to PATH. Verify: `g++ --version`.
2. **VS Code**: Download `VSCodeUserSetup-x64.exe` from the site above, run it, tick "Add to PATH".
3. **Code::Blocks**: Download `codeblocks-XX.XXmingw-setup.exe` (with mingw = bundled g++) from the site above, run it.
4. **Sublime Text**: Download `Sublime Text Build XXXX x64 Setup.exe` from the site above, run it.

See each `.md` file for full details + verification + troubleshooting.
