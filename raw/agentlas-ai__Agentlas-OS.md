# agentlas-ai/Agentlas-OS — raw

- URL: https://github.com/agentlas-ai/Agentlas-OS
- Description: Agent OS: keep specialist agents in a hub, spin up a temporary orchestrator per task. Local-first, works with any model.
- Language: Python
- Topics: a2a, agent, agent-framework, agent-os-desktop, agent-skills, agentic-ai, agentic-workflow, agentos, agents, agents-team, agentshub, ai-agents, autonomous-agents, llm, llm-agents, llm-tools, mcp, multi-agent-systems, ochestration
- Stars: 971
- License: Apache-2.0
- Size: 147,152 KB
- Last push: 2026-07-21
- Fetched: 2026-07-21

## README (excerpt — 676 lines total)

「Agent OS: keep specialist agents in a hub, spin up a temporary orchestrator per task. Local-first, works with any model.」

## ARCHITECTURE.md (full)

Agentlas Core Engine Meta-Agent Team packages the common operating structure behind Agentlas-style agent creation and packaging as a **Markdown-first repo**.

### Meta-Agent Team
```
User request
  -> root meta-agent router
  -> one of:
       10-single-agent-builder
       20-multi-agent-team-builder
       30-agentlas-packager
  -> Agentlas architecture contracts
  -> runtime adapters
  -> verification
```

### Three Core Agents
- `10-single-agent-builder`: 建一個 installable worker package。可加自我演化、研究刷新、記憶架構、runtime adapters，但不會變成一個 team。
- `20-multi-agent-team-builder`: 建 team package，含 orchestrator/HQ、PM Soul、Memory Curator、Policy Gate、workers、eval judge、QA/evidence gate、handoffs、memory、runtime adapters。
- `30-agentlas-packager`: 拿既有 agents/teams，repair 成 Agentlas 架構（public plugin + one-line installer surface）。

### Canonical Core（runtime-neutral）
大量 markdown + JSON contract files，關鍵：
- `AGENTS.md`, `agent.md`
- `docs/agent-trust-contract.md`, `docs/mode-classifier.md`, `docs/clarify-question-loop.md`, `docs/global-command-contract.md`, `docs/skill-lifecycle-promotion.md`, `docs/ontology-runtime.md`, `docs/super-ontology-candidate-contract.md`
- `.agentlas/mode-map.json`, `agent-card.json`, `company-blueprint.json`, `sitemap.json`, `global-commands.json`, `memory-map.json`, `memory-tickets.jsonl`, `vault-references.json`
- `.agentlas/super-ontology-*.json` × 25+ 個 ontology 維度（見下）

### Public Runtime Contracts
- **Agent Trust contract**: agents are **portable user assets** with explicit package identity, owner-scoped private storage, public/private separation, local execution boundaries, governed learning, restore evidence, and **no implied hosted Agent Cloud VM**.
- **Mode classifier**: 三選一（`single-agent-creator` / `team-builder` / `agentlas-packager`）。
- **Clarify question loop**: 1–5 個 package-shaping 問題（mode / runtime target / public boundary / tools / safety unclear 時）。
- **Global command contract**: 每個 generated agent 有 canonical command + runtime command files + final `global_commands` handoff。
- **.agentlas auto-activation**: local runtimes may create/merge public `.agentlas` seed files after activation。
- **Local credential store**: local runtimes materialize real values in gitignored `.env` / `signing/` / `credentials/`；public packages 只保 value-free 名稱、path、stale-check rules。
- **Skill lifecycle registry**: 生 packages ship export-only candidate skill metadata + trial evidence ledgers + Curator decision ledgers。Runtime first-class recall **stays off** until local Curator review + workspace policy approve。
- **Super Ontology candidate contract**: export-only adaptive knowledge governance metadata + coverage seeds + replay ledgers + promotion evidence ledgers。Public exports keep graph writes **value-free** and candidate-only。
- **Production Ontology Runtime**: local-first runtime package。Ingest 支援檔案 → SQLite + FTS5 + deterministic local vectors + source-lineaged chunks + ontology entities/relations + GraphRAG query responses + Memory Curator candidate tickets + Agent Working Memory cache。Parse text / md / json / csv / docx / xlsx / pptx / pdf-text / hwpx / OCR。**Blocks direct durable-memory writes**；missing external parsers recorded as `unsupported_pending_adapter` 而非 pretend success。
- **Gateway channel contract**: Telegram / Slack / Discord / WhatsApp / email / SMS 等 messaging channel。Value-free credential references + sender policies + channel/account/peer bindings + delivery receipts + pairing/admin gates。**Raw provider tokens 不可放 public packages / Hub metadata / memory**。

### Super Ontology 25+ 維度（生成 packages 內帶）
`open-world-coverage`, `consensus-coordination`, `task-coverage`, `contextual-flow`, `causal-impact`, `assurance-case`, `knowledge-homeostasis`, `adversarial-provenance`, `epistemic-calibration`, `semantic-alignment`, `resilience-control`, `invariant-verification`, `observability-telemetry`, `objective-proxy-validity`, `stakeholder-preference-governance`, `normative-authority-drift`, `side-effect-containment`, `source-lineage-version`, `entity-identity-resolution`, `temporal-state-transition`, `capability-delegation-authority`, `privacy-confidentiality-boundary`, `strategic-incentive-compatibility`, `reflexive-feedback-stability`, `replays`, `evidence`, `memory-bridge`。

### Runtime Adapters
同一 core 翻譯到各 runtime：
- Codex: `codex/marketplace.json` + `codex/plugins/agentlas-core-engine-meta-agent/`
- Claude Code: `.claude/commands/` + `.claude/agents/` + `.claude/skills/`
- Gemini CLI: `GEMINI.md` + `.gemini/GEMINI.md` + `.gemini/commands/`
- Generic AGENTS.md tools: root `AGENTS.md`
- Ontology CLI: `bin/ontology` runs local-first storage/search/graph/memory runtime from a shell

**規則**: Adapters 不含 canonical core 沒有的 private logic。

### Packaging Flow
```
existing prompt / agent / team / repo / zip
  -> Agentlas Packager
  -> inspect current structure
  -> classify single-agent or team package
  -> add AGENTS.md canonical core
  -> add or repair agentlas.json
  -> run Hephaestus security scan
  -> compile runtime bundle
  -> add .agentlas contracts
  -> assign global command
  -> add runtime adapters
  -> remove private or unsafe material from public output
  -> verify package
```

### Public Packaging Rule（一眼看起來 intentional）
`README.md` + `ARCHITECTURE.md` + `agents/` + `modes/` + `skills/` + `schemas/` + `agentlas.json` + `scripts/verify-package.sh` + `.agentlas/global-commands.json`

## Manifest
Python-first repo，但 root 沒有 `pyproject.toml`（可能在子目錄）。以 `.agentlas/` JSON contract + `AGENTS.md` 為主要「manifest」。

## Tree (top level — 前 40 條)
```
.agentlas/activation.json
.agentlas/agent-card.json
.agentlas/company-blueprint.json
.agentlas/contract-injection-map.json
.agentlas/curator-decisions.jsonl
.agentlas/global-commands.json
.agentlas/mcp-policy.json
.agentlas/memory-map.json
.agentlas/memory-tickets.jsonl
.agentlas/mode-map.json
.agentlas/project-soul-memory.md
.agentlas/routing-card.json
.agentlas/sitemap.json
.agentlas/skill-registry.json
.agentlas/skill-trials.jsonl
.agentlas/super-ontology-*.json × 25+
.agentlas/super-ontology-*.jsonl × 3
（另有 agents/, modes/, skills/, schemas/, docs/, .claude/, .gemini/, codex/, bin/, examples/, templates/）
```

共 1261 個 blob file（大量 markdown / JSON contract）。
