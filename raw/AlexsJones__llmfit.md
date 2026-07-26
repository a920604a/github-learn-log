# AlexsJones/llmfit — raw

- URL: https://github.com/AlexsJones/llmfit
- Description: Hundreds of models & providers. One command to find what runs on your hardware.
- Language: Rust
- Topics: gguf, llm, localai, mlx, skill, unsloth
- Stars: 30642
- License: MIT
- Size: 27,455 KB
- Fetched: 2026-07-26 (catch-up)

## README (excerpt)

A terminal tool that right-sizes LLM models to your system's RAM, CPU, and GPU. Detects your hardware, scores each model across quality, speed, fit, and context dimensions, and tells you which ones will actually run well on your machine.

Ships with an interactive TUI (default) and a classic CLI mode. Supports multi-GPU setups, MoE architectures, dynamic quantization selection, speed estimation, and local runtime providers (Ollama, llama.cpp, MLX, Docker Model Runner, LM Studio).

### Benchmark & share loop
Download a model, serve it, and measure real tok/s on your hardware — then contribute results back via PR straight from the TUI. No `gh` CLI, no third-party account needed. Every run is saved locally first, your own measurements replace estimates in the fit table, and each merged submission ships in the next release: anyone on identical hardware gets measured `✓` numbers before they ever run a benchmark.

### Install
```
brew install AlexsJones/llmfit/llmfit
scoop install llmfit                             # Windows
port install llmfit                              # MacPorts
curl -fsSL https://llmfit.axjns.dev/install.sh | sh
```

### Sister projects
- sympozium — managing agents in Kubernetes
- llmserve — TUI for serving local LLM models
- llama-panel — native macOS app for llama-server instances

### Core mechanics
- **Hardware detection**：RAM, CPU cores, GPU VRAM, MoE-aware VRAM accounting
- **Model registry**：hundreds of models × providers × quantizations, with metadata（context window, quant format, expected quality）
- **Fit scoring**：4 dimensions - quality / speed / fit（memory headroom）/ context. Each model gets a score per dimension for your specific hardware
- **Dynamic quantization**：picks the biggest quant that fits given headroom
- **Speed estimation**：uses benchmarked baseline + hardware profile → predicted tok/s. Real measurements replace estimates over time
- **Runtime abstraction**：Ollama, llama.cpp, MLX, Docker Model Runner, LM Studio share one "provider" interface

### Data-flow highlight
```
your hardware → detector
                   ↓
model catalog → scorer × 4 dimensions → sorted list（with ✓ measured / ~ estimated tags）
                   ↑
community benchmarks（PR-merged via TUI）
```

### Architecture insight
The interesting design：**a two-way registry**。Models pushed in via community PRs（with hardware/quantization/benchmark data），and estimates get replaced by real measurements as more users contribute. It's a self-improving compatibility database where every user is potentially a data source. The TUI-integrated PR flow removes the friction that would kill contributions in a CLI-only tool.

### Signed distribution
SignPath-signed binaries（interesting for supply-chain trust in AI tooling）

_Fetched via api.github.com on 2026-07-26 for catch-up ingest. Full README (190 lines) includes provider matrix, hardware compatibility notes._
