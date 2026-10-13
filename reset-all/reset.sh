#!/usr/bin/env bash
#
# reset.sh — Reset ALL CP IDEs to latest + factory-fresh state (Ubuntu/Debian)
#
#   Resets:  1) g++ (build-essential + gdb)  2) Code::Blocks
#            3) VS Code                       4) Sublime Text
#
#   What it does, in order:
#     1. Kills running IDE processes (code, subl/sublime_text, codeblocks)
#     2. Backs up existing configs to ~/cp-ide-backup-<timestamp>/ (skip with --no-backup)
#     3. Wipes configs to factory-fresh (VS Code, Sublime, Code::Blocks + extensions/settings)
#     4. Ensures official apt repos exist (VS Code Microsoft, Sublime HQ) — idempotent,
#        handles both legacy .list and modern DEB822 .sources formats
#     5. apt update + installs/upgrades everything to latest
#     6. Verifies binaries + does a real g++ -std=c++17 hello-world compile test
#
#   One-liner (lab PCs):
#     curl -fsSL https://raw.githubusercontent.com/ahsanjust/CP/main/reset-all/reset.sh | bash
#
#   Or clone and run:
#     git clone https://github.com/ahsanjust/CP.git && cd CP && bash reset-all/reset.sh
#
#   Flags:
#     -y, --yes        skip confirmation prompt (needed for non-interactive use)
#     --no-backup      do NOT keep a backup (faster, destructive — not recommended)
#     --dry-run        print what WOULD be done, change nothing
#     -h, --help       show help
#
#   Safety:
#     - Ubuntu/Debian only (requires apt-get). Exits otherwise.
#     - Resolves the REAL user home even when run with sudo (uses SUDO_USER).
#     - Never runs `rm -rf` on empty / / or $HOME — guarded.
#     - Idempotent: safe to run twice in a row.
#     - Piped via curl|bash (stdin not a TTY): skips the prompt automatically,
#       still keeps a backup unless --no-backup is given.
#
#   Restore (if needed):
#     ls ~/cp-ide-backup-*/   # your old settings live here

set -euo pipefail

# ---------- pretty output ----------
say()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf ' \033[1;32m[ok]\033[0m %s\n' "$*"; }
warn() { printf ' \033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- flags ----------
ASSUME_YES=0
NO_BACKUP=0
DRY_RUN=0

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  echo "Usage: bash reset.sh [-y|--yes] [--no-backup] [--dry-run]"
}

for arg in "$@"; do
  case "$arg" in
    -y|--yes)       ASSUME_YES=1 ;;
    --no-backup)    NO_BACKUP=1 ;;
    --dry-run)      DRY_RUN=1 ;;
    -h|--help)      usage; exit 0 ;;
    *) die "Unknown flag: $arg  (try --help)" ;;
  esac
done

# ---------- sudo / privilege ----------
if [[ "$(id -u)" -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

run() {  # run CMD...  (honours --dry-run)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '   [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

run_root() {  # run with sudo if needed (honours --dry-run)
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -n "$SUDO" ]]; then printf '   [dry-run] sudo %s\n' "$*";
    else printf '   [dry-run] %s\n' "$*"; fi
  else
    if [[ -n "$SUDO" ]]; then $SUDO "$@"; else "$@"; fi
  fi
}

command -v apt-get >/dev/null 2>&1 || die "Ubuntu/Debian only (apt-get not found)."
[[ -f /etc/debian_version ]] || warn "/etc/debian_version missing — continuing, apt-get was found."

# ---------- resolve REAL user home (sudo-safe) ----------
TARGET_USER="${SUDO_USER:-$(whoami)}"
# shellcheck disable=SC2086
TARGET_HOME="$(eval echo ~$TARGET_USER)"
[[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || die "Cannot resolve home for user '$TARGET_USER'."
echo "Target user: $TARGET_USER"
echo "Target home: $TARGET_HOME"
if [[ "$(id -u)" -eq 0 && -z "${SUDO_USER:-}" ]]; then
  warn "Running as root directly — configs under /root will be reset. Prefer: sudo -u <student> bash reset.sh  OR  run as the student with sudo rights."
fi

BACKUP_DIR="$TARGET_HOME/cp-ide-backup-$(date +%Y%m%d-%H%M%S)"

# ---------- config paths (factory-reset targets) ----------
# NOTE: kept as an explicit list so nothing unrelated is ever touched.
VSCODE_DIRS=(
  "$TARGET_HOME/.config/Code"
  "$TARGET_HOME/.vscode"
  "$TARGET_HOME/snap/code"          # snap variant (if ever used)
)
SUBLIME_DIRS=(
  "$TARGET_HOME/.config/sublime-text"
  "$TARGET_HOME/.config/sublime-text-3"
  "$TARGET_HOME/.cache/sublime-text"
)
CODEBLOCKS_DIRS=(
  "$TARGET_HOME/.config/codeblocks"
  "$TARGET_HOME/.codeblocks"
  "$TARGET_HOME/.local/share/codeblocks"
)
ALL_CONFIG_DIRS=("${VSCODE_DIRS[@]}" "${SUBLIME_DIRS[@]}" "${CODEBLOCKS_DIRS[@]}")

say "This will RESET to factory-fresh + latest:"
echo "  • VS Code      : ${VSCODE_DIRS[*]}"
echo "  • Sublime Text : ${SUBLIME_DIRS[*]}"
echo "  • Code::Blocks : ${CODEBLOCKS_DIRS[*]}"
echo "  • Packages     : build-essential gdb codeblocks code sublime-text"
if [[ "$NO_BACKUP" -eq 0 ]]; then
  echo "  • Backup       : $BACKUP_DIR"
else
  echo "  • Backup       : SKIPPED (--no-backup — destructive!)"
fi
[[ "$DRY_RUN" -eq 1 ]] && echo "  • Mode         : DRY-RUN (nothing will change)"

# ---------- confirmation (TTY only; auto-skip when piped) ----------
if [[ "$ASSUME_YES" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
  if [[ -t 0 ]]; then
    printf '\nType RESET to wipe IDE settings and continue (anything else aborts): '
    read -r answer || true
    [[ "${answer:-}" == "RESET" ]] || die "Aborted by user. Re-run with --yes for non-interactive use."
  else
    echo "Non-interactive stdin detected (e.g. curl|bash) — proceeding without prompt. Backup: $([[ "$NO_BACKUP" -eq 0 ]] && echo ON || echo OFF)."
  fi
fi

# ---------- 1/6 kill running IDEs ----------
say "1/6  Closing running IDEs (if any)"
# pkill returns 1 when nothing matched — must not abort (set -e). Hence `|| true`.
for p in code codeblocks sublime_text subl; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '   [dry-run] pkill -x %s || true\n' "$p"
  else
    pkill -x "$p" 2>/dev/null || true
  fi
done
if [[ "$DRY_RUN" -eq 0 ]]; then
  sleep 2
  for p in code codeblocks sublime_text subl; do
    pkill -9 -x "$p" 2>/dev/null || true
  done
else
  for p in code codeblocks sublime_text subl; do
    printf '   [dry-run] pkill -9 -x %s || true\n' "$p"
  done
fi
ok "IDEs closed"

# ---------- 2/6 backup ----------
say "2/6  Backup of existing configs"
if [[ "$NO_BACKUP" -eq 1 ]]; then
  warn "backup skipped by --no-backup"
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '   [dry-run] mkdir -p %s\n' "$BACKUP_DIR"
    for d in "${ALL_CONFIG_DIRS[@]}"; do
      printf '   [dry-run] cp -a %s -> %s/ (if exists)\n' "$d" "$BACKUP_DIR"
    done
  else
    mkdir -p "$BACKUP_DIR"
    copied=0
    for d in "${ALL_CONFIG_DIRS[@]}"; do
      if [[ -e "$d" ]]; then
        cp -a -- "$d" "$BACKUP_DIR"/
        echo "   saved: $d"
        copied=1
      fi
    done
    [[ "$copied" -eq 1 ]] && ok "backup at $BACKUP_DIR" || echo "   (no existing configs — nothing to back up)"
  fi
fi

# ---------- 3/6 wipe to factory-fresh ----------
say "3/6  Wiping configs to factory-fresh state"

safe_rm() {  # safe_rm DIR — guarded rm -rf
  local d="$1"
  # Guards: non-empty, not /, not $HOME, must be inside TARGET_HOME or TARGET_HOME/snap.
  if [[ -z "$d" || "$d" == "/" || "$d" == "$TARGET_HOME" ]]; then
    die "Refusing to remove unsafe path: '$d'"
  fi
  case "$d" in
    "$TARGET_HOME"/*) ;;
    *) die "Refusing to remove path outside home: '$d'" ;;
  esac
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '   [dry-run] rm -rf -- %s\n' "$d"
    return 0
  fi
  if [[ -e "$d" ]]; then
    rm -rf -- "$d"
    echo "   wiped: $d"
  else
    echo "   (absent, skip): $d"
  fi
}

for d in "${ALL_CONFIG_DIRS[@]}"; do
  safe_rm "$d"
done
ok "configs are factory-fresh"

# ---------- 4/6 ensure official apt repos (idempotent) ----------
say "4/6  Ensuring official VS Code + Sublime apt repos"

ensure_vscode_repo() {
  # Already configured? (covers .list, .sources, and the microsoft-prod key layout)
  if grep -rq "packages.microsoft.com/repos/code" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "   VS Code repo already present — keeping it."
    return 0
  fi
  echo "   adding VS Code (Microsoft) repo…"
  run_root mkdir -p /etc/apt/keyrings
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "   [dry-run] install microsoft.asc -> /etc/apt/keyrings/ms-vscode.gpg + vscode.list entry"
  else
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor \
      | $SUDO tee /etc/apt/keyrings/ms-vscode.gpg >/dev/null
    $SUDO chmod 644 /etc/apt/keyrings/ms-vscode.gpg
    # shellcheck disable=SC2046
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ms-vscode.gpg] https://packages.microsoft.com/repos/code stable main" \
      | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null
  fi
}

ensure_sublime_repo() {
  if grep -rq "download.sublimetext.com" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "   Sublime repo already present — keeping it."
    return 0
  fi
  echo "   adding Sublime Text (official) repo…"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "   [dry-run] install sublimehq-pub.gpg -> /etc/apt/trusted.gpg.d/sublimehq-archive.gpg + sublime-text.list entry"
  else
    wget -qO- https://download.sublimetext.com/sublimehq-pub.gpg \
      | gpg --dearmor \
      | $SUDO tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg >/dev/null
    $SUDO chmod 644 /etc/apt/trusted.gpg.d/sublimehq-archive.gpg
    echo "deb https://download.sublimetext.com/ apt/stable/" \
      | $SUDO tee /etc/apt/sources.list.d/sublime-text.list >/dev/null
  fi
}

ensure_vscode_repo
ensure_sublime_repo
ok "repos ensured"

# ---------- 5/6 update + install latest ----------
say "5/6  Updating package index + installing latest tools"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "   [dry-run] apt-get update -y"
  echo "   [dry-run] apt-get install -y build-essential gdb wget gpg ca-certificates apt-transport-https"
  echo "   [dry-run] apt-get install -y codeblocks"
  echo "   [dry-run] apt-get install -y code || snap fallback"
  echo "   [dry-run] apt-get install -y sublime-text"
else
  run_root apt-get update -y
  run_root apt-get install -y wget gpg ca-certificates apt-transport-https
  run_root apt-get install -y build-essential gdb
  run_root apt-get install -y codeblocks

  # VS Code: prefer apt (repo ensured above); snap only as fallback like install.sh
  if ! run_root apt-get install -y code; then
    warn "apt 'code' failed — trying snap fallback"
    if command -v snap >/dev/null 2>&1; then
      run_root snap install --classic code || die "Both apt and snap installs of VS Code failed."
    else
      die "apt install of VS Code failed and snap is unavailable."
    fi
  fi

  run_root apt-get install -y sublime-text
fi
ok "latest tools installed"

# ---------- 6/6 verify ----------
say "6/6  Verifying (binaries + real C++17 compile)"
FAIL=0
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "   [dry-run] g++ --version; code --version; subl --version; dpkg-query codeblocks; compile hello-world"
else
  if g++ --version >/dev/null 2>&1; then ok "g++          : $(g++ --version | head -n1)";
  else warn "g++ missing"; FAIL=1; fi

  if command -v code >/dev/null 2>&1; then ok "VS Code      : $(code --version 2>/dev/null | head -n1)";
  else warn "VS Code (code) missing"; FAIL=1; fi

  if command -v subl >/dev/null 2>&1; then ok "Sublime      : $(subl --version 2>/dev/null)";
  else warn "Sublime (subl) missing"; FAIL=1; fi

  if dpkg-query -W codeblocks >/dev/null 2>&1; then ok "Code::Blocks : $(dpkg-query -W -f='${Version}' codeblocks)";
  else warn "Code::Blocks missing"; FAIL=1; fi

  # Real compile test — proves the toolchain (not just the package entry) works.
  TMPD="$(mktemp -d)"
  trap 'rm -rf -- "$TMPD"' EXIT
  printf '#include <bits/stdc++.h>\nusing namespace std;\nint main(){cout<<"CP-OK\\n";}\n' >"$TMPD/t.cpp"
  if g++ -std=c++17 -O2 -o "$TMPD/t" "$TMPD/t.cpp" && [[ "$("$TMPD/t")" == "CP-OK" ]]; then
    ok "g++ C++17 hello-world compiles + runs"
  else
    warn "g++ compile test FAILED"
    FAIL=1
  fi
  trap - EXIT
  rm -rf -- "$TMPD"
fi

echo
if [[ "$FAIL" -ne 0 ]]; then
  die "Reset finished WITH ERRORS — see [!] lines above."
fi

printf '\033[1;32mReset complete.\033[0m IDEs are factory-fresh + latest.\n'
echo "Launch with:  code | subl | codeblocks     Compile with:  g++ -std=c++17 -O2 file.cpp -o file"
if [[ "$NO_BACKUP" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
  echo "Old settings backed up at: $BACKUP_DIR  (delete it once the lab PC looks right)"
fi
