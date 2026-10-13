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
#        (each config gets a UNIQUE backup name — no overwrites; dir chowned to the real user)
#     3. Wipes IDE configs to factory-fresh (VS Code, Sublime, Code::Blocks + extensions/settings)
#        NOTE: the g++/gcc toolchain has no user configs — it is NEVER wiped,
#        only ensured present + upgraded to latest (build-essential + gdb).
#     4. Installs repo prerequisites, then ensures official apt repos exist
#        (VS Code Microsoft, Sublime HQ) — idempotent,
#        handles both legacy .list and modern DEB822 .sources formats
#     5. apt update + installs/upgrades everything to latest
#     6. Verifies binaries (gcc, g++, code, subl, codeblocks)
#        + does a real g++ -std=c++17 hello-world compile test
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
#     --all-users      reset EVERY human user on this PC (UID>=1000, home under
#                      /home). Default resets only the invoking user. Lab PCs with
#                      several student accounts want this. Requires sudo.
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
ALL_USERS=0

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  echo "Usage: bash reset.sh [-y|--yes] [--no-backup] [--all-users] [--dry-run]"
}

for arg in "$@"; do
  case "$arg" in
    -y|--yes)       ASSUME_YES=1 ;;
    --no-backup)    NO_BACKUP=1 ;;
    --all-users)    ALL_USERS=1 ;;
    --dry-run)      DRY_RUN=1 ;;
    -h|--help)      usage; exit 0 ;;
    *) die "Unknown flag: $arg  (try --help)" ;;
  esac
done

BACKUP_TS="$(date +%Y%m%d-%H%M%S)"  # one timestamp so all users' backups match

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

# ---------- resolve target user(s) ----------
# Default: the REAL invoking user even when run with sudo (uses SUDO_USER).
# --all-users: every human account (UID>=1000 with a home under /home).
set_target() {  # set_target USER HOME — (re)builds all per-user globals
  TARGET_USER="$1"
  TARGET_HOME="$2"
  [[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || die "Cannot resolve home for user '$TARGET_USER'."
  BACKUP_DIR="$TARGET_HOME/cp-ide-backup-$BACKUP_TS"
  VSCODE_DIRS=(
    "$TARGET_HOME/.config/Code"
    "$TARGET_HOME/.vscode"
    "$TARGET_HOME/.cache/vscode-ripgrep"  # rg binary cache — safe, re-fetched on demand
    "$TARGET_HOME/snap/code"              # snap variant (if ever used)
  )
  SUBLIME_DIRS=(
    "$TARGET_HOME/.config/sublime-text"
    "$TARGET_HOME/.config/sublime-text-3"  # ST4 keeps using this path on upgraded boxes
    "$TARGET_HOME/.cache/sublime-text"
    "$TARGET_HOME/.cache/sublime-text-3"   # found live on real systems — must wipe
  )
  CODEBLOCKS_DIRS=(
    "$TARGET_HOME/.config/codeblocks"
    "$TARGET_HOME/.codeblocks"
    "$TARGET_HOME/.local/share/codeblocks"
  )
  ALL_CONFIG_DIRS=("${VSCODE_DIRS[@]}" "${SUBLIME_DIRS[@]}" "${CODEBLOCKS_DIRS[@]}")
}

USER_LIST=()
if [[ "$ALL_USERS" -eq 1 ]]; then
  while IFS=: read -r u _ uid _ _ home _; do
    if [[ "$uid" -ge 1000 && "$home" == /home/* && -d "$home" ]]; then
      USER_LIST+=("$u:$home")
    fi
  done < <(getent passwd)
  # Fallback: getent empty (e.g. LDAP hiccup) — scan /home directly.
  if [[ "${#USER_LIST[@]}" -eq 0 ]]; then
    for d in /home/*/; do
      u="$(basename -- "$d")"
      if id "$u" >/dev/null 2>&1 && [[ -d "$d" ]]; then
        USER_LIST+=("$u:$d")
      fi
    done
  fi
  [[ "${#USER_LIST[@]}" -gt 0 ]] || die "--all-users found no human users under /home."
  # Pre-flight: without write access to every home we'd die halfway — fail fast.
  if [[ "$DRY_RUN" -eq 0 ]]; then
    for entry in "${USER_LIST[@]}"; do
      h="${entry#*:}"
      [[ -w "$h" ]] || die "Cannot write $h — re-run with sudo (needed for --all-users)."
    done
  fi
else
  INVOKING_USER="${SUDO_USER:-$(whoami)}"
  # shellcheck disable=SC2086
  INVOKING_HOME="$(eval echo ~$INVOKING_USER)"
  USER_LIST+=("$INVOKING_USER:$INVOKING_HOME")
fi

# Show plan using the first user's paths (identical layout for the rest).
set_target "${USER_LIST[0]%%:*}" "${USER_LIST[0]#*:}"
if [[ "$(id -u)" -eq 0 && -z "${SUDO_USER:-}" && "$ALL_USERS" -eq 0 ]]; then
  warn "Running as root directly — configs under /root will be reset. Prefer: sudo -u <student> bash reset.sh  OR  run as the student with sudo rights."
fi

# Unique backup names — several sources share a basename (sublime-text x2/x3,
# codeblocks x2), so a plain `cp ... BACKUP/` would silently overwrite.
backup_label() {
  case "$1" in
    "$TARGET_HOME/.config/Code")            printf 'config-Code' ;;
    "$TARGET_HOME/.vscode")                 printf 'vscode' ;;
    "$TARGET_HOME/.cache/vscode-ripgrep")   printf 'cache-vscode-ripgrep' ;;
    "$TARGET_HOME/snap/code")               printf 'snap-code' ;;
    "$TARGET_HOME/.config/sublime-text")    printf 'config-sublime-text' ;;
    "$TARGET_HOME/.config/sublime-text-3")  printf 'config-sublime-text-3' ;;
    "$TARGET_HOME/.cache/sublime-text")     printf 'cache-sublime-text' ;;
    "$TARGET_HOME/.cache/sublime-text-3")   printf 'cache-sublime-text-3' ;;
    "$TARGET_HOME/.config/codeblocks")      printf 'config-codeblocks' ;;
    "$TARGET_HOME/.codeblocks")             printf 'home-codeblocks' ;;
    "$TARGET_HOME/.local/share/codeblocks") printf 'local-share-codeblocks' ;;
    *) basename -- "$1" ;;
  esac
}

say "This will RESET to factory-fresh + latest:"
if [[ "$ALL_USERS" -eq 1 ]]; then
  echo "  • Users        : $(printf '%s ' "${USER_LIST[@]%%:*}")"
else
  echo "  • User         : $TARGET_USER  (home: $TARGET_HOME)"
fi
echo "  • VS Code      : ~/.config/Code ~/.vscode ~/.cache/vscode-ripgrep ~/snap/code"
echo "  • Sublime Text : ~/.config/sublime-text ~/.config/sublime-text-3 ~/.cache/sublime-text ~/.cache/sublime-text-3"
echo "  • Code::Blocks : ~/.config/codeblocks ~/.codeblocks ~/.local/share/codeblocks"
echo "  • Packages     : build-essential (gcc + g++) gdb codeblocks code sublime-text"
if [[ "$NO_BACKUP" -eq 0 ]]; then
  echo "  • Backup       : ~/cp-ide-backup-$BACKUP_TS  (inside EACH reset user's home)"
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
# --all-users: kill EVERY user's IDE processes (needs root) so a second student's
# open Sublime can't rewrite its configs after we've wiped them.
kill_one() {  # kill_one SIGNAL PROC — honours DRY_RUN; system-wide with --all-users
  local sig="$1" p="$2" disp
  disp="pkill ${sig:--TERM} -x $p"
  # (already-root sees every user's processes, so prefix sudo only when it exists)
  [[ "$ALL_USERS" -eq 1 && -n "$SUDO" ]] && disp="sudo $disp"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '   [dry-run] %s || true\n' "$disp"
    return 0
  fi
  if [[ "$ALL_USERS" -eq 1 ]]; then
    if [[ -n "$sig" ]]; then run_root pkill "$sig" -x "$p" 2>/dev/null || true
    else run_root pkill -x "$p" 2>/dev/null || true; fi
  else
    if [[ -n "$sig" ]]; then pkill "$sig" -x "$p" 2>/dev/null || true
    else pkill -x "$p" 2>/dev/null || true; fi
  fi
}
for p in code codeblocks sublime_text subl plugin_host-3.3 plugin_host-3.8; do
  kill_one "" "$p"
done
if [[ "$DRY_RUN" -eq 0 ]]; then
  sleep 2
fi
for p in code codeblocks sublime_text subl plugin_host-3.3 plugin_host-3.8; do
  kill_one "-9" "$p"
done
ok "IDEs closed"

# ---------- 2/6 backup + 3/6 wipe (per user) ----------
safe_rm() {  # safe_rm DIR — guarded rm -rf (uses current TARGET_HOME)
  local d="$1"
  # Guards: non-empty, not /, not $HOME, must be inside TARGET_HOME.
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

reset_one_user() {  # reset_one_user USER HOME — backup then wipe to factory-fresh
  set_target "$1" "$2"
  echo
  echo "--- user: $TARGET_USER  (home: $TARGET_HOME) ---"

  say "2/6  Backup of existing configs [$TARGET_USER]"
  if [[ "$NO_BACKUP" -eq 1 ]]; then
    warn "backup skipped by --no-backup"
  else
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf '   [dry-run] mkdir -p %s\n' "$BACKUP_DIR"
      for d in "${ALL_CONFIG_DIRS[@]}"; do
        printf '   [dry-run] cp -a %s -> %s/%s (if exists)\n' "$d" "$BACKUP_DIR" "$(backup_label "$d")"
      done
    else
      mkdir -p "$BACKUP_DIR"
      copied=0
      for d in "${ALL_CONFIG_DIRS[@]}"; do
        if [[ -e "$d" ]]; then
          cp -a -- "$d" "$BACKUP_DIR/$(backup_label "$d")"
          echo "   saved: $d -> $BACKUP_DIR/$(backup_label "$d")"
          copied=1
        fi
      done
      # mkdir/cp ran as root when invoked via sudo — hand the backup back to its owner.
      if [[ "$(id -u)" -eq 0 && "$TARGET_USER" != "root" ]]; then
        chown -R -- "$TARGET_USER" "$BACKUP_DIR" || warn "could not chown $BACKUP_DIR to $TARGET_USER"
      fi
      [[ "$copied" -eq 1 ]] && ok "backup at $BACKUP_DIR" || echo "   (no existing configs — nothing to back up)"
    fi
  fi

  say "3/6  Wiping configs to factory-fresh state [$TARGET_USER]"
  for d in "${ALL_CONFIG_DIRS[@]}"; do
    safe_rm "$d"
  done
  ok "configs are factory-fresh [$TARGET_USER]"
}

for entry in "${USER_LIST[@]}"; do
  reset_one_user "${entry%%:*}" "${entry#*:}"
done

# ---------- 4/6 ensure official apt repos (idempotent) ----------
say "4/6  Ensuring official VS Code + Sublime apt repos"

# Bootstrap FIRST: repo keys below need wget/gpg, which minimal systems may lack.
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "   [dry-run] apt-get update -y"
  echo "   [dry-run] apt-get install -y wget gpg ca-certificates apt-transport-https"
else
  run_root apt-get update -y
  run_root apt-get install -y wget gpg ca-certificates apt-transport-https
fi

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
      | $SUDO tee /etc/apt/keyrings/ms-vscode.gpg >/dev/null \
      || die "Failed to fetch the VS Code key (network down? packages.microsoft.com reachable?). Re-run to retry."
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
      | $SUDO tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg >/dev/null \
      || die "Failed to fetch the Sublime key (network down? download.sublimetext.com reachable?). Re-run to retry."
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
  echo "   [dry-run] apt-get update -y  (repos changed above)"
  echo "   [dry-run] apt-get install -y build-essential gdb"
  echo "   [dry-run] apt-get install -y codeblocks"
  echo "   [dry-run] apt-get install -y code || snap fallback"
  echo "   [dry-run] apt-get install -y sublime-text"
else
  run_root apt-get update -y
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
# Freshness note: `code --version` / `subl --version` were sandbox-tested to
# create NOTHING under $HOME, so they are safe to run post-wipe. The
# `codeblocks` GUI binary is deliberately NEVER launched here (first launch
# must generate its own default.conf) — dpkg + PATH presence is the check.
say "6/6  Verifying (binaries + real C++17 compile)"
FAIL=0
check_ver() {  # check_ver LABEL CMD... — requires non-empty version output
  local label="$1"; shift
  local ver=""
  ver="$("$@" 2>/dev/null | head -n1)" || ver=""
  if [[ -n "$ver" ]]; then ok "$label: $ver";
  else warn "$label missing or broken"; FAIL=1; fi
}
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "   [dry-run] gcc --version; g++ --version; code --version; subl --version; dpkg-query codeblocks; compile hello-world"
else
  check_ver "gcc          " gcc --version
  check_ver "g++          " g++ --version
  if command -v code >/dev/null 2>&1; then check_ver "VS Code      " code --version;
  else warn "VS Code (code) missing"; FAIL=1; fi
  if command -v subl >/dev/null 2>&1; then check_ver "Sublime      " subl --version;
  else warn "Sublime (subl) missing"; FAIL=1; fi
  if dpkg-query -W codeblocks >/dev/null 2>&1; then ok "Code::Blocks : $(dpkg-query -W -f='${Version}' codeblocks)";
  else warn "Code::Blocks missing"; FAIL=1; fi
  command -v codeblocks >/dev/null 2>&1 || { warn "Code::Blocks (codeblocks) not on PATH"; FAIL=1; }

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
echo "First open of each IDE will look brand-new (welcome screens, no extensions, no old projects)."
if [[ "$NO_BACKUP" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
  for entry in "${USER_LIST[@]}"; do
    set_target "${entry%%:*}" "${entry#*:}"
    echo "Old settings for $TARGET_USER backed up at: $BACKUP_DIR"
  done
  echo "(delete those backup dirs once the lab PC looks right)"
fi
