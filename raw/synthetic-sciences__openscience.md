# synthetic-sciences/openscience — raw

- URL: https://github.com/synthetic-sciences/openscience
- Description: The open-source AI workbench for scientific research
- Language: TypeScript
- Topics: agent, ai, ai-agent, bun, cli, co-scientist, llm, ml, ml-engineering, open-source, research, research-tools, science, scientific-computing, typescript
- Stars: 2660
- License: Apache-2.0
- Size: 50,647 KB
- Last push: 2026-07-17
- Fetched: 2026-07-21

## README (excerpt)

OpenScience is an AI workbench for scientific research. You give it a goal, and it works through the research loop the way a capable collaborator would. It reads the papers that matter, forms a hypothesis, writes and runs code, runs experiments on real compute, queries the major scientific databases, and writes up the result. It runs as a workspace in your browser and works with any frontier or open-weight model from Anthropic, OpenAI, Google, and dozens of other providers, using your own API keys. No account is required.

### What it does
- **Runs the whole loop.** Literature review → hypothesis → code → experiment → analysis → write-up, one continuous session.
- **Research agents.** `research` agent by default, plus `biology`, `physics`, `ml` specialists, plus critique / literature-review sub-agents and a read-only `plan` mode.
- **290+ skills.** Training (DeepSpeed, PEFT, TRL), evaluation, dataset work, molecular/clinical biology, cheminformatics, papers/LaTeX, figures, cloud compute.
- **Scientific databases as tools.** UniProt, PDB, Ensembl, ChEMBL, PubChem, arXiv, OpenAlex, Semantic Scholar, ~30 more.
- **Real workspace.** Browser UI: file tree, editor, terminal, session history, inline rendering for molecules / structures / genomes / plots.
- **Extensible.** LSP, MCP servers, plugins, custom agents, TypeScript SDK.

### Install
```bash
npm install -g @synsci/openscience
openscience
```

### How it works (from README)
OpenScience runs a **local server** that hosts the workspace UI, the agent runtime, and the tool layer. The server binds to `127.0.0.1` with Host + Origin allowlist enforcement — **no remote mode**. Sessions/artifacts/provenance stored on disk, shareable as links.

## ARCHITECTURE.md (full)

### The shape of the system

```
  Browser workspace  (frontend/workspace, SolidJS)
        |  HTTP + SSE, localhost only
        v
  Local server       (backend/cli/src/server)

        +--  Agent runtime      sessions, message loop, model routing
        +--  Tool layer         shell, edit, LSP, MCP, science connectors
        +--  Skills             bundled and user-installed skill packs
        +--  Providers          Anthropic, OpenAI, Google, and 75+ more

        +--  Atlas client       optional: managed models, wallet, graph
```

### Repository layout
```
backend/cli          The CLI, server, agent runtime, tools, and skills
frontend/workspace   The workspace UI (SolidJS), served by the CLI
frontend/ui          Shared UI components, themes, and fonts
frontend/docs        The documentation and session-share site (Astro)
frontend/landing     The marketing site (openscience.sh)
tooling/sdk/js       The TypeScript SDK, generated from the server contract
tooling/plugin       The plugin runtime (@synsci/plugin)
tooling/launcher     The `npx synsci` installer
tooling/repo         Release automation
tooling/script       Build helper used across packages
tooling/util         Shared TypeScript utilities (@synsci/util)
tooling/patches      Dependency patches applied at install time
```

### Backend (`backend/cli`)

Bun + TypeScript compiled to a single native binary per platform.

- `src/index.ts` — CLI commands + boot; running `openscience` with no subcommand opens the workspace (`src/cli/cmd/web.ts`).
- `src/server` — Hono server; serves embedded workspace UI, exposes session/tool APIs, streams events back to browser over SSE.
- `src/session` — agent runtime: message loop, tool dispatch, compaction, provenance, **optional blind reviewer gate** at finalize.
- `src/agent` — agent registry + prompts. Default `research`; `biology` / `physics` / `ml` specialists; `plan` = read-only mode.
- `src/provider` — routes request to model. Model defs from [models.dev](https://models.dev), cached locally with bundled snapshot fallback.
- `src/tool` + `src/science` — tools: shell / editor / LSP bridge / MCP client / scientific database connectors.
- `src/openscience` — Atlas client (optional; base install works without it).

### Prompt architecture
Two layers:
1. Provider-level system prompt selected by model (`src/session/system.ts`)
2. Agent-level workflow prompt injected by agent name (`src/session/prompt.ts`)

### Skills
- Loaded on demand (`src/skill`)
- Released builds fetch catalog from Atlas skill index and cache
- Running from source loads bundled `skills/` tree directly
- Small set of system skills (e.g. `initialize-atlas-graph`) embedded

### Configuration & state
- Global config: `~/.config/openscience/openscience.json`
- Project config: `openscience.json` or `.openscience/` at repo root
- On-disk state (sessions, auth, caches) under XDG dirs

### Atlas integration
Atlas is a **separate, closed platform**. Only its client lives here. Wire contract:
- `synsci` model provider id
- `thk_` wallet keys
- `/api/cli/*` endpoints
- Billing classification (`byok` / `managed` / `oauth-free`) decided client-side, server is billing authority

### Build & release
- `backend/cli/script/build.ts` fetches model catalog → builds workspace UI → compiles CLI to native binaries (Linux/macOS/Windows)
- Each platform binary its own npm package (`@synsci/openscience-<platform>`)
- Small meta package (`@synsci/openscience`) selects right one at install
- `npx synsci` launcher installs meta package

## Manifest (package.json — root)

（monorepo，root package.json 定義 workspaces）

## Tree (top level)
```
.editorconfig
.github/{CODEOWNERS, FUNDING.yml, dependabot.yml, pull_request_template.md, workflows/}
.gitignore
.gitleaksignore
.husky/{pre-commit, pre-push}
.openscience/{env.d.ts, openscience.jsonc}
.prettierignore
AGENTS.md
ARCHITECTURE.md
CHANGELOG.md
CLAUDE.md
CODE_OF_CONDUCT.md
CONTRIBUTING.md
LICENSE
NOTICE
README.md
SECURITY.md
assets/wordmark.svg
backend/
bun.lock
bunfig.toml
frontend/
install
package.json
tooling/
tsconfig.json
turbo.json
```

## Key entry file: `backend/cli/src/index.ts` (未拉，見 ARCHITECTURE §Backend)
