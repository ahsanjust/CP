# VS Code — Downloading Guideline

Official download: https://code.visualstudio.com/download  
C++ setup docs: https://code.visualstudio.com/docs/languages/cpp

## Option A: Ubuntu 24.04

**Method 1 — snap (easiest):**
```bash
sudo snap install --classic code
code --version
```

**Method 2 — official .deb (recommended for auto-updates via apt):**
```bash
# Download VSCodeUserSetup .deb from site above, then:
cd ~/Downloads
sudo apt install ./code_*.deb
code --version
```

**Method 3 — Microsoft apt repo:**
```bash
sudo apt install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code
```

## Option B: Windows 10/11

1. Go to https://code.visualstudio.com/download
2. Download **Windows x64 User Installer** (`VSCodeUserSetup-x64.exe`).
3. Run it → Accept → tick **"Add to PATH"** → Next → Finish.
4. Install C++ support:
   - Open VS Code → Extensions (Ctrl+Shift+X) → install **C/C++** (by Microsoft) + **Code Runner** (optional).
   - Install g++ via MSYS2 (see [g++.md](./g++.md)), then configure `MinGW` per https://code.visualstudio.com/docs/cpp/config-mingw

## Verify

```bash
code --version
code hello.cpp
```

Compile from integrated terminal (Ctrl+`):
```bash
g++ -std=c++17 -O2 -Wall hello.cpp -o hello && ./hello
```

## Troubleshooting

- `code: command not found` (Linux): `sudo snap alias code.code code` or reinstall via .deb, then reopen terminal.
- Compiler not found in VS Code: install `build-essential` (Ubuntu) / MSYS2 toolchain (Windows) and restart VS Code.
