---
name: "arch-review"
description: "Principal Architect review: AWS/SOLID/CNCF frameworks, security, testing, AI patterns, technical debt"
tools: ["executeCommand", "readFile", "searchFiles", "editFile", "listDirectory", "webSearch"]
---

# Principal Architect Review

Perform a comprehensive architectural review of the current project considering:

- **AWS Well-Architected Framework** - Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability
- **Azure Well-Architected Framework** - Cost Optimization, Operational Excellence, Performance Efficiency, Reliability, Security
- **CNCF Cloud Native principles** - Containerization, orchestration, microservices, observability
- **AI Systems Engineering Patterns** - LLM integration patterns (see `ai-patterns` instruction)
- **Design Patterns** - Architectural, creational, and behavioral patterns
- **SOLID Design principles** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Code practices** - Code quality, naming conventions, function design, documentation
- **CAP Theorem implications** - Consistency, Availability, Partition tolerance trade-offs
- **Quality Gates & Testing Standards** - Test coverage metrics, API testing, regression testing, edge cases
- **Security Gates** - Zero-tolerance vulnerability policies, secret scanning, dependency monitoring
- **Technical Debt Management** - File management policies, directory structure, debt prevention

## Analysis Steps

1. **Project Structure Analysis**: Detect technology stack, examine configuration files, identify architectural patterns
2. **Specification Review**: Find and analyze specifications, requirements, or ADRs
3. **Implementation Coverage**: Evaluate how well specifications are implemented
4. **Quality Gates Assessment**: Test coverage (target: >=85%), API testing completeness (target: 100%), lint/type errors (target: 0)
5. **Security Posture Analysis**: Secret management, dependency security, vulnerability scanning
6. **Code Quality Evaluation**: Lint configurations, type safety, pre-commit hooks
7. **Technical Debt Assessment**: Forbidden file patterns (_fix, _old, _backup, _temp), directory structure cleanliness
8. **AI/LLM Integration Assessment** (if applicable): Input handling, caching strategies, routing, guardrails, resilience
9. **Documentation Generation**: Create report in `docs/arch-review-YYYY-MM-DD-HHMMSS.md`

Focus on providing actionable recommendations prioritized by impact and effort. Categorize by priority (Critical, High, Medium, Low) with clear implementation guidance and success metrics.
