# CP

One folder, one command — downloads & installs **g++**, **Code::Blocks**, **VS Code**, **Sublime Text** (Ubuntu/Debian):

```bash
curl -fsSL https://raw.githubusercontent.com/ahsanjust/CP/main/install-all/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/ahsanjust/CP.git && cd CP && bash install-all/install.sh
```

## What it installs

| Tool | Source |
|------|--------|
| g++ + gdb | `apt` → `build-essential` |
| Code::Blocks | `apt` → `codeblocks` |
| VS Code | snap (fallback: Microsoft apt repo) |
| Sublime Text | official Sublime apt repo |

Windows: install manually from [msys2.org](https://www.msys2.org/) (g++), [codeblocks.org](https://www.codeblocks.org/downloads/binaries/), [code.visualstudio.com/download](https://code.visualstudio.com/download), [sublimetext.com/download](https://www.sublimetext.com/download).
