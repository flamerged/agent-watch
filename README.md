# Agent Watch

Agent Watch is a SwiftBar/xbar-compatible menu bar plugin for seeing which local coding agents are running, which model/provider targets they appear to use, what folders they are working in, and which local LLM backends or helper services are online.

It is built for local agent-heavy development setups with tools such as Codex, Claude Code, Gemini ACP, OpenCode, Ollama, and oMLX. More specific tools such as aichat and AgentMemory are autodetected when present.

## Features

- Shows detected local agent processes with PID, uptime, version, working folder, model or provider target, and helper process count.
- Detects local LLM and helper backends, including Ollama, oMLX, and optional AgentMemory.
- Groups known MCP/helper processes by owner and type, with per-process debug output behind `AGENTWATCH_SHOW_HELPERS=1`.
- Shows installed coding CLIs and versions when they are discoverable on `PATH`.
- Supports cached update checks for npm-distributed CLIs; checks are spaced by `AGENTWATCH_UPDATE_TTL_SECONDS`.
- Shows the Agent Watch plugin version and, when installed from a git checkout, an update action.
- Hides process command lines by default. Optional redacted command output can be enabled with `AGENTWATCH_SHOW_COMMANDS=1`.
- Uses only local process inspection and local HTTP endpoints by default.

## Install

### SwiftBar

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar).
2. Download the latest release plugin into your SwiftBar plugin folder:

```sh
mkdir -p "$HOME/SwiftBarPlugins"
curl -fsSL \
  https://github.com/flamerged/agent-watch/releases/latest/download/agent-watch.30s.sh \
  -o "$HOME/SwiftBarPlugins/agent-watch.30s.sh"
chmod +x "$HOME/SwiftBarPlugins/agent-watch.30s.sh"
```

SwiftBar will pick up `agent-watch.30s.sh` and refresh every 30 seconds.

### xbar

Agent Watch uses the BitBar/xbar stdout menu format and includes xbar metadata. Install the latest release asset into your xbar plugin folder:

```sh
mkdir -p "$HOME/Library/Application Support/xbar/plugins"
curl -fsSL \
  https://github.com/flamerged/agent-watch/releases/latest/download/agent-watch.30s.sh \
  -o "$HOME/Library/Application Support/xbar/plugins/agent-watch.30s.sh"
chmod +x "$HOME/Library/Application Support/xbar/plugins/agent-watch.30s.sh"
```

### Development Install

Clone the repo only when you want a source checkout for development:

```sh
git clone https://github.com/flamerged/agent-watch.git
cd agent-watch
./scripts/install-dev-swiftbar.sh "$HOME/SwiftBarPlugins"
```

Release installs show `Update to latest release`, so normal users do not need git. Source checkout installs show the current branch and commit for diagnostics, but hide the menu updater to avoid overwriting checkout-managed files. Development updates should use normal git commands in the checkout.

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

The plugin also supports a local config file at `~/.config/agent-watch/config.env`. Open or create it from the `Agent Watch` menu section with `Open config file`. The file accepts simple `AGENTWATCH_KEY=value` lines; it is parsed as data and is not sourced as shell code. Environment variables supplied by the launcher override values from this file.

| Variable | Default | Purpose |
| --- | --- | --- |
| `AGENTWATCH_CONFIG_FILE` | `$HOME/.config/agent-watch/config.env` | Agent Watch config file path |
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
| `AGENTWATCH_CHECK_UPDATES` | `1` | Set to `0` to disable cached update checks |
| `AGENTWATCH_UPDATE_TTL_SECONDS` | `86400` | Minimum seconds between automatic registry checks when update checks are enabled |
| `AGENTWATCH_UPDATE_CACHE` | `$HOME/.cache/agent-watch/cli-updates.tsv` | Update check cache path |
| `AGENTWATCH_SHOW_CONFIG_ACTIONS` | `0` | Set to `1` to show local config-file open actions |
| `AGENTWATCH_SHOW_BACKEND_ACTIONS` | `0` | Set to `1` to show backend web/log open actions for detected services |
| `AGENTWATCH_REPO_DIR` | empty | Optional Agent Watch git checkout for source metadata |
| `AGENTWATCH_REPO_URL` | `https://github.com/flamerged/agent-watch` | Project page opened from the menu |
| `AGENTWATCH_RELEASE_ASSET_URL` | `https://github.com/flamerged/agent-watch/releases/latest/download/agent-watch.30s.sh` | Latest release asset URL used by copied-plugin updates |
| `AGENTWATCH_UPDATE_LOG` | `$HOME/.cache/agent-watch/update.log` | Update log path |
| `AGENTWATCH_INTERESTING_PORTS` | `8000,11434,3000,4000,5000` | Comma-separated TCP listening ports to show |

## Privacy And Security

Agent Watch is intended for local observability. It does not send telemetry.

By default it inspects the local process table with `ps`, working directories and listening ports with `lsof`, selected local config files listed above, and local HTTP status endpoints for detected local services. It does not inspect arbitrary project files.

Process command lines are hidden by default because they can contain sensitive arguments. If `AGENTWATCH_SHOW_COMMANDS=1` is enabled, commands are still passed through a redactor for common API keys, bearer tokens, GitHub tokens, Anthropic/OpenAI-style keys, Gemini keys, Slack tokens, and Context7 tokens.

Update checks are enabled by default. Agent Watch uses package registry lookups only to refresh a local cache, not on every menu refresh.

The default update-check TTL is one day. Set `AGENTWATCH_UPDATE_TTL_SECONDS` to adjust that interval, or use the menu action to refresh the cache manually.

The "Watched Local Ports" section is controlled by `AGENTWATCH_INTERESTING_PORTS`. By default it watches the configured oMLX port, the configured Ollama port, and common local development ports `3000`, `4000`, and `5000`.

The Agent Watch section shows the plugin version, config path, and script path. Release installs also show `Update to latest release`, which runs in the background, logs to `AGENTWATCH_UPDATE_LOG`, downloads the latest release asset, and replaces the plugin script without requiring git. If the plugin can detect a git checkout, it instead shows the branch and commit for diagnostics and leaves updates to normal git commands.

Local config files may reveal model names, provider URLs, and project paths in the menu output. Do not screen-share the menu if those are sensitive.

## Development

Run the local checks:

```sh
./scripts/check.sh
```

The checks run `zsh -n` and a smoke execution with command output disabled.

## Releases

PR titles should use Conventional Commits. `fix:` and `perf:` changes produce patch releases, `feat:` changes produce minor releases, and breaking changes produce major releases.

After a releasable PR is squash-merged to `main`, the release workflow tags the merge commit and creates the GitHub Release. It also uploads a release copy of `agent-watch.30s.sh` with the release version embedded. It does not open a separate release PR.

## License

MIT
