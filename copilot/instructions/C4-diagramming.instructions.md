---
description: "C4 Model PlantUML architecture diagram organization"
applyTo: "**/*.puml,**/*.plantuml,**/diagrams/**"
---

# C4 Model PlantUML Diagramming Guidelines

## Modular Include Pattern

1. **Individual Definition Files**: Each system, person, container, or component in its own `.puml` file with a unique identifier
2. **Category Aggregators**: Group related definitions (e.g., `internal-systems.puml`, `external-systems.puml`, `persons.puml`)
3. **Main Diagram Files**: Top-level diagrams composing architecture views (`10-Context.plantuml`, `20-Container.plantuml`, `30-Component.plantuml`)

## Directory Structure

```
docs/diagrams/
├── 10-Context.plantuml       # C1 System Context
├── 20-Container.plantuml     # C2 Container
├── 30-Component.plantuml     # C3 Component
├── systems/                   # System definitions
│   ├── internal-systems.puml
│   ├── external-systems.puml
│   └── *.puml
├── containers/               # Container definitions
├── components/               # Component definitions
└── persons/                  # Person/actor definitions
    ├── persons.puml
    └── *.puml
```

## C4 Level-Specific Guidelines

### C1 Context Diagram
- Include ALL systems (internal and external) for complete system context
- Use bulk include files
- Focus on high-level relationships

### C2 Container Diagram
- Use selective includes to avoid conflicts
- A system in C1 may become a System_Boundary in C2
- Include only external systems that directly interact with containers

### C3 Component Diagram
- Drill down into specific container internals
- Include only relevant external dependencies

## Common Pitfalls

### System vs System_Boundary Conflicts
Use selective includes in C2 instead of bulk aggregator files. Redefine elements within the appropriate boundary when needed:

```plantuml
' C2 Container - Use selective includes
!include ./systems/performancecentral.puml
' Don't include ai-agent.puml since it's a System_Boundary here
System_Boundary(AIAgentSystem, "AI Agent System") {
    !include ./containers/containers.puml
}
```

## Naming Conventions

- **Files**: Use lowercase with hyphens (e.g., `api-gateway.puml`)
- **IDs**: Use PascalCase (e.g., `APIGateway`)
- **Boundaries**: Suffix with purpose (e.g., `AIAgentSystem`)

## Best Practices

- Use descriptive labels for all relationships
- Include technology/protocol where relevant
- Use `Lay_*` directives sparingly — let PlantUML auto-layout when possible
- Always verify parent diagrams aren't broken when updating child diagrams
