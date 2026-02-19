---
description: "AI/LLM systems engineering patterns: caching, routing, guardrails, RAG"
applyTo: "**/*.py,**/*.ts,**/*.js,**/prompt*,**/llm*,**/ai*"
---

# AI Systems Engineering Patterns

Reference guide for LLM integration patterns. Based on [AI Systems Engineering Patterns](https://blog.alexewerlof.com/p/ai-systems-engineering-patterns) by Alex Ewerlöf.

## Part 1: Interface Patterns

### 1. Structured JSON Prompting
User submits a JSON object adhering to a strict schema instead of free-form prompts. Validate input against schema (JSON Schema, Zod, Pydantic) before it reaches the LLM.

### 2. Prompt Template Pattern
Treat prompts as source code (version controlled) and user input as variables (injected at runtime). **Security Warning**: Always sanitize user variables before interpolation.

### 3. Structured Outputs
Force AI output to be valid JSON based on a specific schema. Use native Structured Outputs (OpenAI/Anthropic) or libraries like Instructor (Python), Vercel AI SDK (TypeScript).

## Part 2: Prompting & Context Patterns

### 4. Context Caching
Cache static portions of prompts (system instructions, few-shot examples) to reduce token costs and latency. Up to 80% cost reduction possible.

### 5. Progressive Summarization
Recursively compress oldest messages into a "Summary Block" to maintain fixed context size while retaining semantic history.

### 6. Memory Management (Episodic vs Semantic)
Distinguish between episodic memory (conversation events) and semantic memory (facts/knowledge). Observer agent summarizes key facts at conversation end, writes to sidecar database, injects into future sessions.

## Part 3: Routing & Optimization Patterns

### 7. Router Pattern
Classify user intent before routing to appropriate model/tool. Smaller/faster model classifies, then routes to appropriate handler.

### 8. Skills / Lazy Loading
Load tool definitions on-demand rather than all at once. Improves model accuracy when 10+ tools are available.

### 9. Model Selection (Dense vs Sparse)
- **Dense Models**: All parameters active per token. High capability, high cost.
- **Sparse/MoE Models**: Only fraction of parameters active per token. Efficient for high-volume workloads.

## Part 4: Caching & Performance Patterns

### 10. Semantic Caching
Use Vector DB as cache; return cached response if semantically similar question was recently answered.

**Security Critical**: Tenant isolation mandatory. Never cache PII responses across users. Cache keys must be scoped: `(User_ID, Query_Vector)` for private data.

### 11. LLM Gateway
Centralized proxy between applications and Model-as-a-Service providers. Handles authentication, rate limiting, failover, fallback.

## Part 5: Security & Safety Patterns

### 12. Sanitization Middleware (Guardrails)
Layer between user and model for content filtering. Input sanitization (filter prompt injection) and output sanitization (block PII leakage, hallucinated URLs, toxic content).

### 13. Prompt Injection Defense
Mitigations: Input validation, sandboxing unsafe inputs, dedicated detection tools, multi-agent architectures with security agents.

### 14. PII Protection
Detect and redact PII before storage/caching. Tenant-isolated caching. Output scanning before response delivery.

## Part 6: Architecture Patterns

### 15. RAG (Retrieval-Augmented Generation)
Augment LLM with external knowledge retrieval. Embed query, retrieve top-k similar chunks from vector DB, assemble into prompt, generate response.

### 16. Multi-Agent Orchestration
Patterns: Sequential (pipeline), Parallel (concurrent + merge), Hierarchical (orchestrator + specialists), Debate (propose + critique).

### 17. Flow Engineering
Design multi-step workflows breaking complex tasks into manageable segments. Shift from "perfect prompt" to "best flow with correct steps."

## Quick Reference Matrix

| Pattern | Primary Benefit | Key Risk | Complexity |
|---------|----------------|----------|------------|
| Structured JSON | Predictability | Flexibility loss | Low |
| Prompt Template | Consistency | Injection risk | Low |
| Structured Output | Type safety | Creativity limits | Medium |
| Context Caching | Cost reduction | Invalidation | Medium |
| Semantic Caching | Latency/cost | PII leakage | High |
| Router | Cost optimization | Misrouting | Medium |
| Guardrails | Safety | False positives | Medium |
| RAG | Grounding | Retrieval quality | High |
| Multi-Agent | Quality | Complexity | Very High |

## Implementation Checklist

When reviewing AI/LLM integrations, verify:

- [ ] **Input handling**: Structured inputs or sanitized templates?
- [ ] **Output validation**: Structured outputs or post-processing?
- [ ] **Caching strategy**: Semantic caching with tenant isolation?
- [ ] **Routing**: Appropriate model selection per query type?
- [ ] **Security**: Guardrails for input/output? Prompt injection defense?
- [ ] **Resilience**: LLM gateway or fallback strategy?
- [ ] **Cost optimization**: Context caching? Router pattern?
- [ ] **Memory**: Session/semantic memory strategy?
- [ ] **Observability**: Logging, metrics, evaluation loops?
