# Agent Watch

Agent Watch is a SwiftBar/xbar-compatible menu bar plugin for seeing which local coding agents are running, which model/provider targets they appear to use, what folders they are working in, and which local LLM backends or helper services are online.

It is built for local agent-heavy development setups with tools such as Codex, Claude Code, Gemini ACP, OpenCode, Ollama, and oMLX. More specific tools such as aichat and AgentMemory are autodetected when present.

## Features

- Shows detected local agent processes with PID, uptime, version, working folder, model or provider target, and helper process count.
- Detects local LLM and helper backends, including Ollama, oMLX, and optional AgentMemory.
- Groups known MCP/helper processes by owner and type, with per-process debug output behind `AGENTWATCH_SHOW_HELPERS=1`.
- Shows installed coding CLIs and versions when they are discoverable on `PATH`.
- Supports opt-in cached update checks for npm-distributed CLIs with `AGENTWATCH_CHECK_UPDATES=1`; checks are spaced by `AGENTWATCH_UPDATE_TTL_SECONDS`.
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
| `AGENTWATCH_SHOW_HELPERS` | `0` | Set to `1` to show individual MCP/helper processes |
| `AGENTWATCH_CHECK_UPDATES` | `0` | Set to `1` to enable cached update checks |
| `AGENTWATCH_UPDATE_TTL_SECONDS` | `86400` | Minimum seconds between automatic registry checks when update checks are enabled |
| `AGENTWATCH_UPDATE_CACHE` | `$HOME/.cache/agent-watch/cli-updates.tsv` | Update check cache path |
| `AGENTWATCH_SHOW_CONFIG_ACTIONS` | `0` | Set to `1` to show local config-file open actions |
| `AGENTWATCH_SHOW_BACKEND_ACTIONS` | `0` | Set to `1` to show backend web/log open actions for detected services |
| `AGENTWATCH_INTERESTING_PORTS` | `8000,11434,3000,4000,5000` | Comma-separated TCP listening ports to show |

## Privacy And Security

Agent Watch is intended for local observability. It does not send telemetry.

By default it inspects the local process table with `ps`, working directories and listening ports with `lsof`, selected local config files listed above, and local HTTP status endpoints for detected local services. It does not inspect arbitrary project files.

Process command lines are hidden by default because they can contain sensitive arguments. If `AGENTWATCH_SHOW_COMMANDS=1` is enabled, commands are still passed through a redactor for common API keys, bearer tokens, GitHub tokens, Anthropic/OpenAI-style keys, Gemini keys, Slack tokens, and Context7 tokens.

Update checks are disabled by default. When enabled, Agent Watch uses package registry lookups only to refresh a local cache, not on every menu refresh.

The default update-check TTL is one day. Set `AGENTWATCH_UPDATE_TTL_SECONDS` to adjust that interval, or use the menu action to refresh the cache manually.

Local config files may reveal model names, provider URLs, and project paths in the menu output. Do not screen-share the menu if those are sensitive.

## Development

Run the local checks:

```sh
./scripts/check.sh
```

The checks run `zsh -n` and a smoke execution with command output disabled.

## Releases

PR titles should use Conventional Commits. `fix:` and `perf:` changes produce patch releases, `feat:` changes produce minor releases, and breaking changes produce major releases.

Release Please opens and maintains the release PR from commits on `main`. Merging that release PR creates the GitHub release and tag.

## License

MIT
