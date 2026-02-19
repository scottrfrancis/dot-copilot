---
description: "README-centric documentation organization patterns"
applyTo: "**/README.md,**/*.md"
---

# README Documentation Guidelines

## Core Principle

**All user-facing information must be accessible from the README.md file, either directly included or linked.** Users should never need to hunt through the repository structure to find documentation.

## README Structure

### Essential Sections (in this order)

1. **Project Title and Description** - What the project does
2. **Installation/Setup** - How to get started
3. **Usage** - Basic usage examples
4. **Documentation** - Links to all other documentation
5. **Contributing** - How to contribute (if applicable)
6. **License** - Legal information

### Documentation Section

**Do this:**
```markdown
## Documentation

- [User Guide](docs/user-guide.md) - Complete usage instructions
- [API Reference](docs/api/README.md) - Full API documentation
- [Developer Guide](docs/development.md) - Setup for contributors
- [Architecture](docs/architecture.md) - System design and structure
```

**Don't do this:**
```markdown
## Documentation

See the docs folder for more information.
```

## Documentation Organization Patterns

### Pattern 1: Inline README (Small Projects)
Include all documentation directly in README.md.

### Pattern 2: Linked Documentation (Medium Projects)
Use a `docs/` directory with clear navigation from README.

### Pattern 3: Multi-Section Documentation (Large Projects)
Organize by audience: For Users, For Developers, For Contributors.

## Linking Best Practices

1. **Use descriptive link text**: `[User Guide](docs/user-guide.md)` not `[here](docs/user-guide.md)`
2. **Include brief descriptions**: Explain what each linked document contains
3. **Use relative paths**: `docs/guide.md` not `/project/docs/guide.md`
4. **Verify all links work**: Broken documentation links frustrate users

## What Goes in README vs Separate Files

**Include directly in README:**
- Project overview and purpose
- Quick installation steps
- Basic usage example
- Links to all other documentation

**Link to separate files:**
- Detailed installation procedures
- Complete API documentation
- Architecture and design documents
- Contributing guidelines and development setup
