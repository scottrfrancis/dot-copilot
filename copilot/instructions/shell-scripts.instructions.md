---
description: "Shell script best practices: directory management, error handling, portability"
applyTo: "**/*.sh,**/*.bash,**/Makefile"
---

# Shell Script Best Practices

Guidelines for writing maintainable, portable, and reliable shell scripts.

## Directory Management

### Always Detect Script Directory

Scripts should work regardless of where they're called from. Hardcoded paths break when scripts move.

**Do this:**
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Alternative for maximum portability (works with sh):
# SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
```

**Don't do this:**
```bash
source ./config/settings.sh
cd ../data
```

### Use pushd/popd for Directory Navigation

**Do this:**
```bash
pushd "${SCRIPT_DIR}/data" > /dev/null || {
    echo "Error: Cannot access data directory" >&2
    exit 1
}
process_files
popd > /dev/null
```

**Don't do this:**
```bash
cd data
process_files
cd ..
```

### Always Use Absolute Paths from SCRIPT_DIR

```bash
CONFIG_FILE="${SCRIPT_DIR}/config/settings.conf"
DATA_DIR="${SCRIPT_DIR}/data"
LOG_FILE="${SCRIPT_DIR}/logs/process.log"
source "${CONFIG_FILE}"
```

## Error Handling

### Check Directory Changes

```bash
pushd "${SCRIPT_DIR}/work" > /dev/null || {
    echo "Error: Cannot access work directory" >&2
    exit 1
}
```

### Clean Up on Exit

```bash
cleanup() {
    popd > /dev/null 2>&1 || true
}
trap cleanup EXIT
```

## Complete Example

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_DIR="${SCRIPT_DIR}/config"
DATA_DIR="${SCRIPT_DIR}/data"
OUTPUT_DIR="${SCRIPT_DIR}/output"

cleanup() {
    popd > /dev/null 2>&1 || true
}
trap cleanup EXIT

main() {
    echo "Processing data..."
    pushd "${DATA_DIR}" > /dev/null || {
        echo "Error: Cannot access data directory" >&2
        exit 1
    }
    for file in *.csv; do
        [ -f "$file" ] || continue
        echo "Processing: $file"
    done
    popd > /dev/null
    echo "Complete!"
}

main "$@"
```

## Additional Best Practices

1. **Use shellcheck**: Validate scripts with `shellcheck`
2. **Quote variables**: Always quote variable expansions: `"${VAR}"`
3. **Set strict mode**: Use `set -euo pipefail` at the start
4. **Provide usage info**: Include help text for script usage
5. **Log important operations**: Especially for scripts that modify data

## Platform Considerations

- Use `#!/usr/bin/env bash` for better portability
- Avoid bash-specific features if the script needs to run with `sh`
- Test on target platforms (Linux, macOS, WSL, etc.)
