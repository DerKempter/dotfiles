# 🤖 Local AI Developer Agents in Zed

This repository includes a highly optimized, custom developer profile for the rust-native **Zed editor** configured with a private, local-first LLM stack. This setup guarantees maximum privacy, low-latency code completion, and zero external data leaks during development.

---

## 🏗️ Architecture Overview

The local AI developer environment relies on a three-tier architecture:
1. **Zed Editor (Front-end)**: The user interface which handles editor context, document edits, inline completions, and chat loops.
2. **Lemonade LLM Host (Local Server)**: A local OpenAI-compatible inference server running on `localhost:8000` hosting optimized GGUF (ggml) models.
3. **Gemini Registry (Cloud Fallback)**: A registry agent server for model index management.

```mermaid
graph TD
    subgraph System ["Local Developer System"]
        A["Zed Editor"] -->|Inline Edit Predictions (Low Latency)| B["Lemonade Host (v1/ predictions)"]
        A -->|Chat & Commit Agent (High Intelligence)| C["Lemonade Host (api/v1/ chat)"]
        B -->|Inference| D[("qwen3-tk-4b-FLM (GGUF)")]
        C -->|Inference| E[("Qwen3-Coder-30B (GGUF)")]
    end
    A -.->|Registry Server Check| F["Gemini Registry (Cloud)"]

    style A fill:#ff9f1c,stroke:#fff,stroke-width:2px,color:#fff
    style B fill:#2ec4b6,stroke:#fff,stroke-width:2px,color:#fff
    style C fill:#2ec4b6,stroke:#fff,stroke-width:2px,color:#fff
    style D fill:#e71d36,stroke:#fff,stroke-width:2px,color:#fff
    style E fill:#e71d36,stroke:#fff,stroke-width:2px,color:#fff
    style F fill:#c5a3ff,stroke:#fff,stroke-dasharray: 5 5,color:#fff
```

---

## ⚡ Assistant Capabilities

The system is configured to delegate tasks to specific models depending on the required speed and task complexity:

### 1. Inline Edit Predictions (Autocompletion)
- **Model**: `qwen3-tk-4b-FLM`
- **Provider**: `open_ai_compatible_api` (`http://localhost:8000/v1`)
- **Key Settings**:
  - `max_output_tokens`: `128` (optimized for single lines or quick block completions)
  - `mode`: `"subtle"` (unobtrusive suggestions that appear as grey ghost text)
- **Use Case**: Real-time code completions while typing.

### 2. Main Chat Assistant
- **Model**: `Qwen3-Coder-30B-A3B-Instruct-GGUF`
- **Provider**: `lemonade` (`http://localhost:8000/api/v1`)
- **Key Settings**:
  - `dock`: `"right"` (opens as a sidebar panel next to code buffers)
  - `show_turn_stats`: `true` (renders real-time performance data: tokens/sec, prompt evaluation time)
- **Use Case**: Answering complex system design questions, explaining code, refactoring large functions, or writing tests.

### 3. Git Commit Message Generator
- **Model**: `Qwen3-Coder-30B-A3B-Instruct-GGUF`
- **Provider**: `lemonade`
- **Use Case**: Automatically summarizes file diffs and constructs standard semantic git commits inside Zed's Git panel.

---

## 🗃️ Configured Local Model Portfolio

The following models are pre-configured in `.config/zed/settings.json` under the `openai_compatible.lemonade` registry:

| Model Name | Max Context | Description |
|:---|:---|:---|
| `Qwen3-Coder-30B-A3B-Instruct-GGUF` | 32,768 tokens | Primary workspace driver; state-of-the-art coding and instruction model. |
| `Qwen3-Coder-Next-GGUF` | 32,768 tokens | Next-generation iteration for testing experimental features. |
| `Devstral-Small-2507-GGUF` | 32,768 tokens | Lightweight, high-speed alternate model for general code formatting. |
| `gpt-oss-20b-mxfp4-GGUF` | 32,768 tokens | Quantized open-source model optimized for memory efficiency. |
| `user.QwenCoder2.5-1.5B` | 32,768 tokens | Ultra-small model suitable for resource-constrained systems. |

---

## 🔧 Workflows & Usage

### Starting the Local Inference Server
Before launching Zed, ensure your `lemonade` backend (e.g. Llama.cpp, LocalAI, Ollama, or custom wrapper) is running and listening on port `8000`:
```bash
# Verify the endpoint is responsive and returns available models:
curl http://localhost:8000/api/v1/models
```

### Profile Switching
The editor configuration supports environment-specific profiles:
*   **Default Profile**: Uses `biome` as the primary formatting engine across JS, TS, TSX, JSON, JSONC, and CSS.
*   **Angular Profile** (`angular`): Toggles formatting engines to disable Biome and activates `angular`, `vscode-html-language-server`, and `tailwindcss-language-server` for template development.
*   **Dashboard Profile** (`angular-ews-dashboard`): Fine-tuned configuration for large Angular enterprise solutions.
