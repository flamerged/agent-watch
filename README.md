# Agent Watch

Agent Watch is a SwiftBar/xbar-compatible menu bar plugin for seeing which local coding agents are running, which model/provider targets they appear to use, what folders they are working in, and which local LLM or memory backends are online.

It is built for local agent-heavy development setups with tools such as Codex, Claude Code, Gemini ACP, OpenCode, aichat, Ollama, oMLX, and AgentMemory.

## Features

- Shows detected local agent processes with PID, uptime, version, working folder, model or provider target, and helper process count.
- Detects local LLM and memory backends, including Ollama, oMLX, and AgentMemory.
- Groups known MCP/helper processes under likely owning agents when the process tree exposes that relationship.
- Reads common local agent config files to infer default model routes.
- Hides process command lines by default. Optional redacted command output can be enabled with `AGENTWATCH_SHOW_COMMANDS=1`.
- Uses only local process inspection and local HTTP endpoints by default.

## Install

### SwiftBar

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar).
2. Clone this repo.
3. Symlink the plugin into your SwiftBar plugin folder:

```sh
./scripts/install-swiftbar.sh "$HOME/SwiftBarPlugins"
```

SwiftBar will pick up `agent-watch.30s.sh` and refresh every 30 seconds.

### xbar

Agent Watch uses the BitBar/xbar stdout menu format and includes xbar metadata. Install it by copying or symlinking `bin/agent-watch.30s.sh` into your xbar plugin folder.

### Linux

xbar and SwiftBar are macOS menu bar apps. Some Linux menu bar tools, such as Argos for GNOME, can run BitBar-style plugins. Agent Watch avoids macOS-only output format features, but some actions and process details depend on local tools such as `lsof`, `ps`, and `xdg-open`.

## Requirements

- `zsh`
- `ps`
- `lsof`
- `curl`
- `jq`

macOS usually includes most of these. Install `jq` with Homebrew if it is missing:

```sh
brew install jq
```

## Configuration

Agent Watch works without configuration, but these environment variables can tailor it to your setup:

| Variable | Default | Purpose |
| --- | --- | --- |
| `AGENTWATCH_CODEX_CONFIG` | `$HOME/.codex/config.toml` | Codex config path |
| `AGENTWATCH_CLAUDE_SESSIONS` | `$HOME/.claude/sessions` | Claude Code session metadata directory |
| `AGENTWATCH_AICHAT_CONFIG` | `$HOME/Library/Application Support/aichat/config.yaml` | aichat config path |
| `AGENTWATCH_OPENCODE_CONFIG` | `$HOME/.config/opencode/opencode.json` | OpenCode config path |
| `AGENTWATCH_OMLX_URL` | `http://127.0.0.1:8000` | oMLX server URL |
| `AGENTWATCH_OLLAMA_URL` | `http://127.0.0.1:11434` | Ollama server URL |
| `AGENTWATCH_AGENTMEMORY_URL` | `http://127.0.0.1:3111` | AgentMemory API URL |
| `AGENTWATCH_AGENTMEMORY_VIEWER_URL` | `http://127.0.0.1:3113` | AgentMemory viewer URL |
| `AGENTWATCH_OMLX_API_KEY` | empty | Optional oMLX bearer token for model status |
| `AGENTWATCH_OMLX_API_KEY_FILE` | empty | Optional file containing the oMLX bearer token |
| `AGENTWATCH_SHOW_COMMANDS` | `0` | Set to `1` to show redacted process commands |
| `AGENTWATCH_INTERESTING_PORTS` | local agent/backend ports | Comma-separated TCP listening ports to show |

## Privacy And Security

Agent Watch is intended for local observability. It does not send telemetry.

By default it inspects the local process table with `ps`, working directories and listening ports with `lsof`, selected local config files listed above, and local HTTP status endpoints for oMLX, Ollama, and AgentMemory. It does not inspect arbitrary project files.

Process command lines are hidden by default because they can contain sensitive arguments. If `AGENTWATCH_SHOW_COMMANDS=1` is enabled, commands are still passed through a redactor for common API keys, bearer tokens, GitHub tokens, Anthropic/OpenAI-style keys, Gemini keys, Slack tokens, and Context7 tokens.

Local config files may reveal model names, provider URLs, and project paths in the menu output. Do not screen-share the menu if those are sensitive.

## Development

Run the local checks:

```sh
./scripts/check.sh
```

The checks run `zsh -n` and a smoke execution with command output disabled.

## License

MIT
