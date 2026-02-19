---
description: "Shell quoting, TTY handling, VS Code terminal compatibility"
applyTo: "**/*.sh,**/*.bash,**/Dockerfile"
---

# Shell Escaping and Terminal Compatibility Guidelines

Guidelines for writing shell scripts that work consistently across different terminal environments (VS Code, native terminals, CI/CD).

## Key Principles

### 1. Never Use Line Continuations Inside Quoted Strings

**Wrong** - Backslash inside quotes creates literal backslash:
```bash
local docker_cmd="docker run --rm \
    -v $(pwd):/workspace \
    my-image"
```

**Correct** - Build commands incrementally:
```bash
# Option 1: Incremental building
local docker_cmd="docker run --rm"
docker_cmd="$docker_cmd -v $(pwd):/workspace"
docker_cmd="$docker_cmd my-image"

# Option 2: Single line (preferred for simple commands)
local docker_cmd="docker run --rm -v $(pwd):/workspace my-image"

# Option 3: Array building (best for complex commands)
local docker_args=(
    "docker" "run" "--rm"
    "-v" "$(pwd):/workspace"
    "my-image"
)
"${docker_args[@]}"
```

### 2. Handle TTY Detection for Different Terminals

```bash
local docker_flags="--rm"
if [ -t 0 ] && [ "$QUIET" != true ] && [ "$CI" != true ]; then
    docker_flags="-it --rm"
fi
```

### 3. Minimize eval Usage

Prefer direct execution or arrays for complex commands:
```bash
local cmd_array=("$base_cmd" "$arg1" "$arg2")
"${cmd_array[@]}"
```

### 4. Quote Variables Consistently

```bash
docker run -v "$PWD:/workspace" image
```

## Environment-Specific Considerations

| Aspect | VS Code Terminal | Native Terminal | Recommendation |
|--------|------------------|-----------------|----------------|
| TTY Detection | May return false | Usually true | Check context flags |
| Line Continuation | More forgiving | Strict parsing | Avoid in strings |
| Color Output | Good support | Full support | Use `--color=auto` |
| Signal Handling | Limited | Full support | Test both environments |

## Testing Checklist

- [ ] Native terminal (bash, zsh)
- [ ] VS Code integrated terminal
- [ ] SSH session (often no TTY)
- [ ] CI/CD environment (GitHub Actions, etc.)
- [ ] With special characters in paths (spaces, quotes)
- [ ] Quiet and verbose modes

## Debugging Commands

```bash
[ -t 0 ] && echo "TTY available" || echo "No TTY"
echo "TERM: ${TERM:-not set}"
set -x  # Enable debug mode
printf '%q\n' "$your_variable"  # Shows how bash sees the variable
```

Remember: **Test early, test in multiple environments, and prefer simple over clever.**
