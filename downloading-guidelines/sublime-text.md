# Sublime Text — Downloading Guideline

Official download: https://www.sublimetext.com/download

## Option A: Ubuntu / Debian (Official APT repo - Recommended)

```bash
# 1. Add GPG key
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

# 2. Add stable channel
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

# 3. Install
sudo apt update
sudo apt install -y sublime-text

# 4. Verify
subl --version
```

## Option B: Ubuntu (Manual .deb)

1. Go to https://www.sublimetext.com/download
2. Download **64 bit .deb** under Linux.
3. Install:
   ```bash
   cd ~/Downloads
   sudo apt install ./sublime-text_build_*_amd64.deb
   ```

## Option C: Windows 10/11

1. Go to https://www.sublimetext.com/download
2. Under Windows, click **64 bit Setup** (`Sublime Text Build XXXX x64 Setup.exe`).
3. Run installer → Next → Finish.
4. For C++ single-file run (optional): install `mingw` g++ first (see [g++.md](./g++.md)), then Tools → Build System → New Build System:
   ```json
   {
     "cmd": ["g++", "-std=c++17", "-O2", "${file}", "-o", "${file_path}/${file_base_name}"],
     "file_regex": "^(..[^:]*):([0-9]+):?([0-9]+)?:? (.*)$",
     "working_dir": "${file_path}",
     "selector": "source.c++",
     "variants": [
       { "name": "Run", "cmd": ["${file_path}/${file_base_name}"] }
     ]
   }
   ```

## Verify

```bash
subl --version
subl hello.cpp
```

## Notes

- Sublime Text is free to evaluate, paid license for continued use.
- Enable `View → Show Console` for error logs. Package Control: https://packagecontrol.io/installation
