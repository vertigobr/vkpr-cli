# Description

Runs `rit create formula`, removes unnecessary files and fixes configs in order to keep it exclusively as a shell local formula.

Files/folders removed:

- build.bat
- Dockerfile
- Makefile
- set_umask.sh
- src/windows/
- src/main.bat

Files changed:

- `config.json` (remove inputs array content)
- `build.sh` (remove windows builds)
- `metadata.json` (remove docker execution)

## Command

Interactive inputs:

```bash
vkpr create formula
```

Non-interactive:

```bash
vkpr create formula --vkpr_formula="vkpr object verb"
```
