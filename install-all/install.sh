#!/usr/bin/env bash
#
# install.sh — One command to download & install ALL CP tools on Ubuntu/Debian:
#   1) g++ (build-essential + gdb)   2) Code::Blocks
#   3) VS Code                       4) Sublime Text
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/ahsanjust/CP/main/install-all/install.sh | bash

set -euo pipefail

say()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf ' \033[1;32m[ok]\033[0m %s\n' "$*"; }
warn() { printf ' \033[1;33m[!]\033[0m %s\n' "$*"; }

[[ "$(id -u)" -eq 0 ]] && SUDO="" || SUDO="sudo"

command -v apt-get >/dev/null 2>&1 || { echo "Ubuntu/Debian only (apt-get not found)."; exit 1; }

say "Updating package index"
$SUDO apt-get update -y

say "1/4  g++ (build-essential + gdb + wget/gpg)"
$SUDO apt-get install -y build-essential gdb wget gpg ca-certificates

say "2/4  Code::Blocks"
$SUDO apt-get install -y codeblocks

say "3/4  VS Code"
if ! command -v code >/dev/null 2>&1; then
  if command -v snap >/dev/null 2>&1; then
    $SUDO snap install --classic code || warn "snap failed -> using Microsoft apt repo"
  fi
fi
if ! command -v code >/dev/null 2>&1; then
  $SUDO apt-get install -y apt-transport-https
  $SUDO mkdir -p /etc/apt/keyrings
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | $SUDO tee /etc/apt/keyrings/ms-vscode.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ms-vscode.gpg] https://packages.microsoft.com/repos/code stable main" \
    | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null
  $SUDO apt-get update -y
  $SUDO apt-get install -y code
fi

say "4/4  Sublime Text (official apt repo)"
wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg \
  | gpg --dearmor \
  | $SUDO tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg >/dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" \
  | $SUDO tee /etc/apt/sources.list.d/sublime-text.list >/dev/null
$SUDO apt-get update -y
$SUDO apt-get install -y sublime-text

say "Verifying"
g++ --version >/dev/null 2>&1 && ok "g++      : $(g++ --version | head -n1)" || warn "g++ missing"
command -v code >/dev/null 2>&1 && ok "VS Code  : $(code --version 2>/dev/null | head -n1)" || warn "VS Code missing"
command -v subl >/dev/null 2>&1 && ok "Sublime  : $(subl --version 2>/dev/null)" || warn "Sublime missing"
dpkg-query -W codeblocks >/dev/null 2>&1 && ok "Code::Blocks : $(dpkg-query -W -f='${Version}' codeblocks)" || warn "Code::Blocks missing"

printf '\n\033[1;32mAll done.\033[0m Launch with: code, subl, codeblocks  |  compile: g++ -std=c++17 -O2 file.cpp\n'
