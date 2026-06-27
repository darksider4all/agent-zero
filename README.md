<div align="center">

# `Agent Zero` — homelab data fork

> **What this repo is.** Personal fork of [`agent0ai/agent-zero`](https://github.com/agent0ai/agent-zero)
> used as the **host-side bind-mount source** for the agent-zero container on the homelab
> gateway (LXC 105 / 192.168.0.115). `usr/`, `logs/`, and `docker/run/` here are mounted live
> into the running container. See [Homelab deployment notes](#homelab-deployment-notes) at the bottom
> for layout, the locally-built image, and the patches that diverge from upstream.

# Agent Zero
### A full Linux system for your AI agent.

Agent Zero is an open, dynamic, organic agentic framework. One Docker container ships a full Linux system with a desktop and a plugin hub that the agent can extend using Skills.

[![Website](https://img.shields.io/badge/Website-agent--zero.ai-0A192F?style=for-the-badge&logo=vercel&logoColor=white)](https://agent-zero.ai)
[![Docs](https://img.shields.io/badge/Docs-Read%20the%20guides-1F6FEB?style=for-the-badge&logo=readthedocs&logoColor=white)](./docs/)
[![Discord](https://img.shields.io/badge/Discord-Join%20us-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/B8KZKNsPpj)
[![GitHub Sponsors](https://img.shields.io/badge/Sponsors-Thank%20you-FF69B4?style=for-the-badge&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/agent0ai)

[Install](#how-to-install) |
[Launcher](#a0-launcher) |
[What's Different](#what-makes-agent-zero-different) |
[A0 CLI](#a0-cli-connector-extend-onto-your-host-machine) |
[Docs](#documentation)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/agent0ai/agent-zero)
[Ask ChatGPT](https://chatgpt.com/?q=Analyze%20this%3A%20https%3A%2F%2Fgithub.com%2Fagent0ai%2Fagent-zero) |
[Ask Claude](https://claude.ai/new?q=Analyze%20this%3A%20https%3A%2F%2Fgithub.com%2Fagent0ai%2Fagent-zero)


</div>

<div align="center">
<a href="https://www.youtube.com/watch?v=k78HX_RA9Q0&t=19s">
<img src="docs/res/thumbnail-install.webp" alt="Agent Zero Installation Guide" width="100%"/>
</a>
</div>

# How To Install

Choose the install path that matches your machine.

| Path | Best for | What it does |
| --- | --- | --- |
| **A0 Launcher** | Desktop users who want the guided path | Downloads Agent Zero, creates and manages local Instances, and helps set up the container runtime when needed. |
| **A0 Install** | Terminals, SSH sessions, servers, and scripted setup | Installs Agent Zero from the command line, reuses an existing Docker-compatible runtime first, and can run headlessly. |
| **Docker** | Machines that already have Docker ready | Runs the Agent Zero container directly. |

## A0 Launcher

The desktop **A0 Launcher** is the recommended way to install Agent Zero on a personal machine. Download the Launcher, open it, and let it check your local runtime. If Docker is missing or stopped, the Launcher offers a setup path before it downloads Agent Zero. If you already host Agent Zero elsewhere, add it as a remote Instance and use the Launcher without local Docker setup.

### Downloads

| Architecture | macOS | Linux | Windows |
| --- | --- | --- | --- |
| x86 | [Mac Intel](https://github.com/agent0ai/a0-launcher/releases/download/v1.0/a0-launcher-1.0-macos-x64.dmg) | [Linux x86](https://github.com/agent0ai/a0-launcher/releases/download/v1.0/a0-launcher-1.0-linux-x64.AppImage) | [Windows x86](https://github.com/agent0ai/a0-launcher/releases/download/v1.0/a0-launcher-1.0-windows-x64.exe) |
| ARM64 | [Mac Apple Silicon](https://github.com/agent0ai/a0-launcher/releases/download/v1.0/a0-launcher-1.0-macos-arm64.dmg) | [Linux ARM64](https://github.com/agent0ai/a0-launcher/releases/download/v1.0/a0-launcher-1.0-linux-arm64.AppImage) | [Windows ARM64](https://github.com/agent0ai/a0-launcher/releases/download/v1.0/a0-launcher-1.0-windows-arm64.exe) |

See the [A0 Launcher v1.0 release](https://github.com/agent0ai/a0-launcher/releases/tag/v1.0) for release notes and updater metadata. See the [Launcher guide](./docs/guides/launcher.md) for the first-run walkthrough.

## A0 Install

Use **A0 Install** when you want the terminal path: SSH sessions, servers, recovery shells, or a scriptable setup. It creates Dockerized Agent Zero instances, mounts each instance's data into `/a0/usr` inside the container, and uses a reuse-before-setup policy: it tries your current Docker CLI configuration, `DOCKER_HOST`, Docker contexts, and known local Docker-compatible endpoints before setting up a runtime.

### macOS / Linux

```bash
curl -fsSL https://bash.agent-zero.ai | bash
```

### Windows PowerShell

```powershell
irm https://ps.agent-zero.ai | iex
```

### Headless / scripted

For servers and automation, run the installer in Quick Start mode so it creates one instance and exits without opening menus:

```bash
curl -fsSL https://bash.agent-zero.ai | bash -s -- --quick-start --name agent-zero --port 5080
```

```powershell
& ([scriptblock]::Create((irm https://ps.agent-zero.ai))) -QuickStart -Name agent-zero -Port 5080
```

Use `--skip-runtime-setup` / `-SkipRuntimeSetup` when Docker must already be working and the installer should not try to set up a runtime. See the [A0 Install repository](https://github.com/agent0ai/a0-install) for all installer flags.

## Docker already installed? Run this directly

```bash
docker run -p 80:80 -v a0_usr:/a0/usr agent0ai/agent-zero
```

Open the Web UI, configure your LLM provider, and start with a concrete task. For the full setup and onboarding experience, see the [Installation guide](./docs/setup/installation.md).

# What Makes Agent Zero Different

## A Real Linux Desktop in the Canvas

<img alt="Agent Zero driving Blender in its built-in XFCE desktop" src="docs/res/usage/webui/agentzero-xfce-computer.gif" />
<br>

Agent Zero opens its own Linux desktop inside the right-side Canvas. Not a remote VM, not a shared clipboard, but a real XFCE desktop session running in the container.

That means the agent can drive *real desktop software*: open Blender to model a 3D object, jump into a terminal window, manage files visually, run a GUI tool that has no API.

You watch every action, and you can intervene at any moment because your mouse and keyboard share the same desktop.

See the [Desktop guide](./docs/guides/desktop.md) for the walkthrough, prompt examples, and how Desktop differs from Browser.

## Native Browser With DOM Annotations

<img alt="Annotating a webpage element in the Agent Zero browser" src="docs/res/usage/browser/annotation.gif" />
<br>

Agent Zero ships a built-in Browser with an optional live surface in the Canvas. The agent can open pages, read them, click, type, upload files, and take screenshots - the usual. The unusual part is **Annotate mode**.

Annotate mode turns any webpage into an interactive directive surface. Click an element to:

- **Change it** - "make this button blue and round the corners" runs as a JS instruction the agent applies and verifies.
- **Inspect it** - pull the DOM, the styles, the parent chain, the framework hints into the conversation.
- **Lift it** - see a card, hero, or component on someone else's site that you like? Capture it and have the agent re-implement it in your own project's stack.
- **Comment it** - leave actionable notes pinned to elements during a UI review; the agent reads the comments and ships the fixes.

The Docker browser is the default live Browser surface. Browser history keeps screenshots of important steps, so older chats can still show what the agent saw. The Browser also supports Chrome extensions inside the Docker browser, and **Bring Your Own Browser** through the A0 CLI Connector lets the agent drive Chrome/Edge/Chromium on your own machine.

See the [Browser guide](./docs/guides/browser.md) for screenshots, settings, host-browser setup, and troubleshooting.

## Cowork on Documents

### Markdown Editor With Live Cowork

<img alt="Agent Zero writing a TODO plan in the Canvas markdown editor" src="docs/res/usage/webui/markdown-editor.gif" />
<br>

The Canvas includes a rich Markdown editor designed for genuine cowork. Ask the agent to "write a plan to do X in a TODO.md in the open doc" and you'll see the file appear in the editor, character by character, while you keep typing in another section.

## 👀 Keep in Mind

1. **Agent Zero Can Be Dangerous!**

- With proper instruction, Agent Zero is capable of many things, even potentially dangerous actions concerning your computer, data, or accounts. Always run Agent Zero in an isolated environment (like Docker) and be careful what you wish for.

2. **Agent Zero Is Prompt-based.**

- The whole framework is guided by the **prompts/** folder. Agent guidelines, tool instructions, messages, utility AI functions, it's all there.


## 📚 Read the Documentation

| Page | Description |
|-------|-------------|
| [Installation](./docs/setup/installation.md) | Installation, setup and configuration |
| [Usage](./docs/guides/usage.md) | Basic and advanced usage |
| [Guides](./docs/guides/) | Step-by-step guides: Usage, Projects, API Integration, MCP Setup, A2A Setup |
| [Development Setup](./docs/setup/dev-setup.md) | Development and customization |
| [WebSocket Infrastructure](./docs/developer/websockets.md) | Real-time WebSocket handlers, client APIs, filtering semantics, envelopes |
| [Extensions](./docs/developer/extensions.md) | Extending Agent Zero |
| [Connectivity](./docs/developer/connectivity.md) | External API endpoints, MCP server connections, A2A protocol |
| [Architecture](./docs/developer/architecture.md) | System design and components |
| [Contributing](./docs/guides/contribution.md) | How to contribute |
| [Troubleshooting](./docs/guides/troubleshooting.md) | Common issues and their solutions |


## 🎯 Changelog

GitHub release notes for the latest eligible `main` tag are generated during `.github/workflows/docker-publish.yml` from commit subjects and descriptions since the previous published release, using OpenRouter and the editable prompt in `scripts/openrouter_release_notes_system_prompt.md`.

### v0.9.8 - Skills, UI Redesign & Git projects
[Release video](https://youtu.be/NV7s78yn6DY)

- Skills
    - Skills System replacing the legacy Instruments with a new `SKILL.md` standard for structured, portable agent capabilities.
    - Built-in skills, and UI support for importing and listing skills
- Real-time WebSocket infrastructure replacing the polling-based approach for UI state synchronization
- UI Redesign
    - Process groups to visually group agent actions with expand/collapse support
    - Timestamps, steps count and execution time with tool-specific badges
    - Step detail modals with key-value and raw JSON display
    - Collapsible responses with show more/less and copy buttons on code blocks and tables
    - Message queue system allowing users to queue messages while the agent is still processing
    - In-browser file editor for viewing and editing files without leaving the UI
    - Welcome screen redesign with info and warning banners for connection security, missing API keys, and system resources
    - Scheduler redesign with standalone modal, separate task list, detail and editor components, and project support
    - Smooth response rendering and scroll stabilization across chat, terminals, and image viewer
    - Chat width setting and reworked preferences panel
    - Image viewer improvements with scroll support and expanded viewer
    - Redesigned sidebar with reusable dropdown component and streamlined buttons
    - Inline button confirmations for critical actions
    - Improved login design and new logout button
    - File browser enhanced with rename and file actions dropdown
- Git projects
    - Git-based projects with clone authentication for public and private repositories
- Four new LLM providers: CometAPI, Z.AI, Moonshot AI, and AWS Bedrock
- Microsoft Dev Tunnels integration for secure remote access
- User data migration to `/usr` directory for cleaner separation of user and system files
- Subagents system with configurable agent profiles for different roles
- Memory operations offloaded to deferred tasks for better performance
- Environment variables can now configure settings via `A0_SET_*` prefix in `.env`
- Automatic migration with overwrite support for `.env`, scheduler, knowledge, and legacy directories
- Projects support extended to MCP, A2A, and external API
- Workdir outside project support for more flexible file organization
- Agent number tracking in backend and responses for multi-agent identification
- Many bug fixes and stability improvements across the UI, MCP tools, scheduler, uploads, and WebSocket handling


### v0.9.7 - Projects
[Release video](https://youtu.be/RrTDp_v9V1c)
- Projects management
    - Support for custom instructions
    - Integration with memory, knowledge, files
    - Project specific secrets 
- New Welcome screen/Dashboard
- New Wait tool
- Subordinate agent configuration override support
- Support for multiple documents at once in document_query_tool
- Improved context on interventions
- Openrouter embedding support
- Frontend components refactor and polishing
- SSH metadata output fix
- Support for windows powershell in local TTY utility
- More efficient selective streaming for LLMs
- UI output length limit improvements

### v0.9.6 - Memory Dashboard
[Release video](https://youtu.be/sizjAq2-d9s)
- Memory Management Dashboard
- Kali update
- Python update + dual installation
- Browser Use update
- New login screen
- LiteLLM retry on temporary errors
- Github Copilot provider support

### v0.9.5 - Secrets
[Release video](https://www.youtube.com/watch?v=VqxUdt7pjd8)
- Secrets management - agent can use credentials without seeing them
- Agent can copy paste messages and files without rewriting them
- LiteLLM global configuration field
- Browser agent configuration improvements
- Progressive web app support
- Extra model params support for JSON
- Short IDs for files and memories to prevent LLM errors
- Tunnel component frontend rework
- Fix for timezone change bug
- Notifications z-index fix

### v0.9.4 - Connectivity, UI
[Release video](https://www.youtube.com/watch?v=C2BAdDOduIc)
- External API endpoints
- Streamable HTTP MCP A0 server
- A2A (Agent to Agent) protocol - server+client
- New notifications system
- New local terminal interface for stability
- Rate limiter integration to models
- Delayed memory recall
- Smarter autoscrolling in UI
- Action buttons in messages
- Multiple API keys support
- Download streaming
- Tunnel URL QR code
- Internal fixes and optimizations

### v0.9.3 - Subordinates, memory, providers Latest
[Release video](https://www.youtube.com/watch?v=-LfejFWL34k)
- Faster startup/restart
- Subordinate agents can have dedicated prompts, tools and system extensions
- Streamable HTTP MCP server support
- Memory loading enhanced by AI filter
- Memory AI consolidation when saving memories
- Auto memory system configuration in settings
- LLM providers available are set by providers.yaml configuration file
- Venice.ai LLM provider supported
- Initial agent message for user + as example for LLM
- Docker build support for local images
- File browser fix

### v0.9.2 - Kokoro TTS, Attachments
[Release video](https://www.youtube.com/watch?v=sPot_CAX62I)

- Kokoro text-to-speech integration
- New message attachments system
- Minor updates: log truncation, hyperlink targets, component examples, api cleanup

### v0.9.1 - LiteLLM, UI improvements
[Release video](https://youtu.be/crwr0M4Spcg)
- Langchain replaced with LiteLLM
    - Support for reasoning models streaming
    - Support for more providers
    - Openrouter set as default instead of OpenAI
- UI improvements
    - New message grouping system
    - Communication smoother and more efficient
    - Collapsible messages by type
    - Code execution tool output improved
    - Tables and code blocks scrollable
    - More space efficient on mobile
- Streamable HTTP MCP servers support
- LLM API URL added to models config for Azure, local and custom providers

### v0.9.0 - Agent roles, backup/restore
[Release video](https://www.youtube.com/watch?v=rMIe-TC6H-k)
- subordinate agents can use prompt profiles for different roles
- backup/restore functionality for easier upgrades
- security and bug fixes

### v0.8.7 - Formatting, Document RAG Latest
[Release video](https://youtu.be/OQJkfofYbus)
- markdown rendering in responses
- live response rendering
- document Q&A tool

### v0.8.6 - Merge and update
[Release video](https://youtu.be/l0qpK3Wt65A)
- Merge with Hacking Edition
- browser-use upgrade and integration re-work
- tunnel provider switch

### v0.8.5 - **MCP Server + Client**
[Release video](https://youtu.be/pM5f4Vz3_IQ)

- Agent Zero can now act as MCP Server
- Agent Zero can use external MCP servers as tools

### v0.8.4.1 - 2
Default models set to gpt-4.1
- Code execution tool improvements
- Browser agent improvements
- Memory improvements
- Various bugfixes related to context management
- Message formatting improvements
- Scheduler improvements
- New model provider
- Input tool fix
- Compatibility and stability improvements

### v0.8.4
[Release video](https://youtu.be/QBh_h_D_E24)

- **Remote access (mobile)**

### v0.8.3.1
[Release video](https://youtu.be/AGNpQ3_GxFQ)

- **Automatic embedding**

### v0.8.3
[Release video](https://youtu.be/bPIZo0poalY)

- ***Planning and scheduling***

### v0.8.2
[Release video](https://youtu.be/xMUNynQ9x6Y)

- **Multitasking in terminal**
- **Chat names**

### v0.8.1
[Release video](https://youtu.be/quv145buW74)

- **Browser Agent**
- **UX Improvements**

### v0.8
[Release video](https://youtu.be/cHDCCSr1YRI)

- **Docker Runtime**
- **New Messages History and Summarization System**
- **Agent Behavior Change and Management**
- **Text-to-Speech (TTS) and Speech-to-Text (STT)**
- **Settings Page in Web UI**
- **SearXNG Integration Replacing Perplexity + DuckDuckGo**
- **File Browser Functionality**
- **KaTeX Math Visualization Support**
- **In-chat File Attachments**

### v0.7
[Release video](https://youtu.be/U_Gl0NPalKA)

- **Automatic Memory**
- **UI Improvements**
- **Instruments**
- **Extensions Framework**
- **Reflection Prompts**
- **Bug Fixes**

## 🤝 Community and Support

- [Join our Discord](https://discord.gg/B8KZKNsPpj) for live discussions or [visit our Skool Community](https://www.skool.com/agent-zero).
- [Follow our YouTube channel](https://www.youtube.com/@AgentZeroFW) for hands-on explanations and tutorials
- [Report Issues](https://github.com/agent0ai/agent-zero/issues) for bug fixes and features

---

## Homelab deployment notes

This checkout is the **host-side data directory** for the running agent-zero container. Most of the tree is just the upstream working copy; only the subdirs and files listed under "Layout" actually drive the deployment, and the patches under "Local-only commits" are the only deltas vs `upstream/main`.

### Layout

| Path on host | Mount target in container | Purpose |
|---|---|---|
| `usr/` | `/a0/usr/` (bind mount) | User plugins, chats, scheduler tasks, FAISS memory store, knowledge graph, MemPalace data, project workdirs |
| `logs/` | `/a0/logs/` (bind mount) | Agent runtime logs (per-chat HTML transcripts, mempalace-api.log, …) |
| `docker/run/docker-compose.yml` | — | The compose file that brings up the container; pins the image and bind mounts |
| `docker/run/agent-zero/` | — | Local build context (`DockerfileLocal`, install scripts, copied git tree) for the locally-built image. Gitignored. |
| `data/` | — | Misc local working dir; gitignored. |

### Running image

- **Image:** `agent-zero-homelab:v2.1-p1`
- **Source repo:** [`darksider4all/agent-zero`](https://github.com/darksider4all/agent-zero) on branch `homelab` (upstream v2.1 + two framework patches; see that repo's README for details)
- **Container name:** `agent-zero`
- **Port:** `50080:80` on the agent LXC (192.168.0.115)
- **Limits:** `mem_limit: 3g`, `memswap_limit: 4g`
- **Companion container on the same host:** `ollama-embed` serving `snowflake-arctic-embed2` (1024-dim, CPU)

### Local-only commits on top of `upstream/main` (branch `main`)

| Commit | Title | What changed |
|---|---|---|
| [`6c29563`](https://github.com/darksider4all/agent-zero/commit/6c29563) | memory cold-start retry, increase container memory limit | `usr/plugins/_memory/extensions/python/monologue_start/_10_memory_init.py` — retry `_memory` init on 400 / connection errors with 10–45 s backoff to ride out the ollama-embed cold-start race. `docker/run/docker-compose.yml` — raise `mem_limit` 2 g → 3 g and `memswap_limit` 3 g → 4 g to prevent OOM under heavy load. `.gitignore` — exclude the nested `docker/run/agent-zero/` build context. |
| [`76bc7395`](https://github.com/darksider4all/agent-zero/commit/76bc7395) | ops(compose): point at locally-built `agent-zero-homelab:v2.1-p1` | `docker/run/docker-compose.yml` (+1 −1) — switches `image:` from upstream `agent0ai/agent-zero:latest` (v1.20-based) to the locally-built `agent-zero-homelab:v2.1-p1` (upstream v2.1 + truncation + mobile CSS patches from the `agent-zero-src` homelab branch). |

### Sync with upstream

```bash
git fetch upstream
git checkout main
git rebase upstream/main   # or: git merge upstream/main
```

### Operations cheatsheet

```bash
# Bring the container up / down
cd docker/run && docker compose up -d
cd docker/run && docker compose down

# In-container service control (safe — does not touch the container itself)
docker exec agent-zero supervisorctl status
docker exec agent-zero supervisorctl restart run_ui

# Memory store backups (one-off)
ls /root/agent-zero-data/usr/memory/default/*.bak_*
```
