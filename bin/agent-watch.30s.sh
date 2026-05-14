#!/bin/zsh
# <xbar.title>Agent Watch</xbar.title>
# <xbar.version>v0.1.0</xbar.version> # x-release-please-version
# <xbar.author>flamerged</xbar.author>
# <xbar.author.github>flamerged</xbar.author.github>
# <xbar.desc>Shows local coding agents, model/provider targets, folders, versions, helper processes, and local LLM backends.</xbar.desc>
# <xbar.dependencies>zsh, ps, lsof, curl, jq</xbar.dependencies>
# <xbar.abouturl>https://github.com/flamerged/agent-watch</xbar.abouturl>
# <xbar.var>string(AGENTWATCH_OMLX_URL="http://127.0.0.1:8000"): oMLX server URL</xbar.var>
# <xbar.var>string(AGENTWATCH_OLLAMA_URL="http://127.0.0.1:11434"): Ollama server URL</xbar.var>
# <xbar.var>boolean(AGENTWATCH_SHOW_COMMANDS=false): Show redacted process commands</xbar.var>
# <xbar.var>boolean(AGENTWATCH_SHOW_HELPERS=false): Show individual MCP/helper processes</xbar.var>
# <xbar.var>boolean(AGENTWATCH_CHECK_UPDATES=false): Check latest CLI versions from package registries</xbar.var>
# <xbar.var>string(AGENTWATCH_UPDATE_TTL_SECONDS="86400"): Seconds between update checks when enabled</xbar.var>
# <xbar.var>boolean(AGENTWATCH_SHOW_CONFIG_ACTIONS=false): Show config-file open actions</xbar.var>
# <xbar.var>boolean(AGENTWATCH_SHOW_BACKEND_ACTIONS=false): Show detected backend web/log open actions</xbar.var>
# <xbar.var>string(AGENTWATCH_INTERESTING_PORTS="8000,11434,3000,4000,5000"): TCP ports to show</xbar.var>
# <swiftbar.title>Agent Watch</swiftbar.title>
# <swiftbar.version>v0.1.0</swiftbar.version> # x-release-please-version
# <swiftbar.author>flamerged</swiftbar.author>
# <swiftbar.desc>Shows local coding agents, model/provider targets, folders, versions, helper processes, and local LLM backends.</swiftbar.desc>
# <swiftbar.refresh>30s</swiftbar.refresh>

set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
for extra_bin in "$HOME/.bun/bin" "$HOME/.cargo/bin" "$HOME/.local/share/mise/shims" "$HOME/.asdf/shims"; do
  [[ -d "$extra_bin" ]] && export PATH="$extra_bin:$PATH"
done
for node_bin in "$HOME"/.nvm/versions/node/*/bin(N); do
  export PATH="$node_bin:$PATH"
done

JQ="${AGENTWATCH_JQ:-$(command -v jq 2>/dev/null || true)}"
CURL="${AGENTWATCH_CURL:-$(command -v curl 2>/dev/null || true)}"
LSOF="${AGENTWATCH_LSOF:-$(command -v lsof 2>/dev/null || true)}"
PS="${AGENTWATCH_PS:-$(command -v ps 2>/dev/null || true)}"
SED="${AGENTWATCH_SED:-$(command -v sed 2>/dev/null || true)}"
AWK="${AGENTWATCH_AWK:-$(command -v awk 2>/dev/null || true)}"

emit() {
  builtin print -r -- "$@"
}

print() {
  builtin print -r -- "$@"
}

have() {
  [[ -n "${1:-}" && -x "$1" ]]
}

strip_slash() {
  local value="${1:-}"
  emit "${value%/}"
}

url_port() {
  local url="${1:-}"
  local port=""
  have "$SED" && port="$(emit "$url" | "$SED" -nE 's#^[a-zA-Z][a-zA-Z0-9+.-]*://[^/:]+:([0-9]+).*#\1#p')"
  emit "$port"
}

open_target() {
  local target="${1:-}"
  [[ -z "$target" ]] && return 0
  if command -v open >/dev/null 2>&1; then
    open "$target" >/dev/null 2>&1 &
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$target" >/dev/null 2>&1 &
  fi
}

open_app() {
  local app="${1:-}"
  if command -v open >/dev/null 2>&1; then
    open -a "$app" >/dev/null 2>&1 &
  fi
}

CODEX_CONFIG="${AGENTWATCH_CODEX_CONFIG:-$HOME/.codex/config.toml}"
CLAUDE_SESSIONS="${AGENTWATCH_CLAUDE_SESSIONS:-$HOME/.claude/sessions}"
AICHAT_CONFIG="${AGENTWATCH_AICHAT_CONFIG:-$HOME/Library/Application Support/aichat/config.yaml}"
OPENCODE_CONFIG="${AGENTWATCH_OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"
SWIFTBAR_PLUGIN_DIR="${AGENTWATCH_SWIFTBAR_PLUGIN_DIR:-$HOME/SwiftBarPlugins}"
AGENTMEMORY_LOG="${AGENTWATCH_AGENTMEMORY_LOG:-$HOME/local-agentmemory/logs/agentmemory.log}"
OMLX_URL="$(strip_slash "${AGENTWATCH_OMLX_URL:-http://127.0.0.1:8000}")"
OLLAMA_URL="$(strip_slash "${AGENTWATCH_OLLAMA_URL:-http://127.0.0.1:11434}")"
AGENTMEMORY_URL="$(strip_slash "${AGENTWATCH_AGENTMEMORY_URL:-${AGENTMEMORY_URL:-http://127.0.0.1:3111}}")"
AGENTMEMORY_VIEWER_URL="$(strip_slash "${AGENTWATCH_AGENTMEMORY_VIEWER_URL:-http://127.0.0.1:3113}")"
OMLX_ADMIN_URL="${AGENTWATCH_OMLX_ADMIN_URL:-$OMLX_URL/admin}"
OMLX_CHAT_URL="${AGENTWATCH_OMLX_CHAT_URL:-$OMLX_URL/admin/chat}"
OMLX_KEY_FILE="${AGENTWATCH_OMLX_API_KEY_FILE:-}"
OMLX_API_KEY="${AGENTWATCH_OMLX_API_KEY:-}"
SHOW_COMMANDS="${AGENTWATCH_SHOW_COMMANDS:-0}"
SHOW_HELPERS="${AGENTWATCH_SHOW_HELPERS:-0}"
CHECK_UPDATES="${AGENTWATCH_CHECK_UPDATES:-0}"
UPDATE_TTL_SECONDS="${AGENTWATCH_UPDATE_TTL_SECONDS:-86400}"
UPDATE_CACHE="${AGENTWATCH_UPDATE_CACHE:-$HOME/.cache/agent-watch/cli-updates.tsv}"
SHOW_CONFIG_ACTIONS="${AGENTWATCH_SHOW_CONFIG_ACTIONS:-0}"
SHOW_BACKEND_ACTIONS="${AGENTWATCH_SHOW_BACKEND_ACTIONS:-0}"

OMLX_PORT="$(url_port "$OMLX_URL")"
OLLAMA_PORT="$(url_port "$OLLAMA_URL")"
AGENTMEMORY_PORT="$(url_port "$AGENTMEMORY_URL")"
AGENTMEMORY_VIEWER_PORT="$(url_port "$AGENTMEMORY_VIEWER_URL")"
[[ -z "$OMLX_PORT" ]] && OMLX_PORT="8000"
[[ -z "$OLLAMA_PORT" ]] && OLLAMA_PORT="11434"
[[ -z "$AGENTMEMORY_PORT" ]] && AGENTMEMORY_PORT="3111"
[[ -z "$AGENTMEMORY_VIEWER_PORT" ]] && AGENTMEMORY_VIEWER_PORT="3113"
INTERESTING_PORTS="${AGENTWATCH_INTERESTING_PORTS:-$OMLX_PORT,$OLLAMA_PORT,3000,4000,5000}"

truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

update_cache_age() {
  [[ -f "$UPDATE_CACHE" ]] || { print ""; return; }
  if stat -f %m "$UPDATE_CACHE" >/dev/null 2>&1; then
    stat -f %m "$UPDATE_CACHE"
  elif stat -c %Y "$UPDATE_CACHE" >/dev/null 2>&1; then
    stat -c %Y "$UPDATE_CACHE"
  fi
}

npm_latest() {
  local package="$1"
  command -v npm >/dev/null 2>&1 || return
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 npm view "$package" version 2>/dev/null
  else
    npm view "$package" version 2>/dev/null
  fi
}

write_update_cache() {
  mkdir -p "${UPDATE_CACHE:h}" 2>/dev/null || return
  local tmp="$UPDATE_CACHE.$$"
  : > "$tmp" || return
  local now latest
  now="$(date +%s 2>/dev/null || print "0")"
  for row in \
    "codex	@openai/codex" \
    "claude	@anthropic-ai/claude-code" \
    "opencode	opencode-ai" \
    "gemini	@google/gemini-cli"; do
    local tool="${row%%	*}"
    local package="${row#*	}"
    command -v "$tool" >/dev/null 2>&1 || continue
    latest="$(npm_latest "$package" | head -1)"
    [[ -n "$latest" ]] && emit "${tool}	${latest}	${now}" >> "$tmp"
  done
  mv "$tmp" "$UPDATE_CACHE"
}

cached_latest_version() {
  local tool="$1"
  [[ -f "$UPDATE_CACHE" ]] || return
  have "$AWK" || return
  "$AWK" -F '\t' -v t="$tool" '$1 == t {print $2; exit}' "$UPDATE_CACHE" 2>/dev/null
}

maybe_refresh_update_cache() {
  truthy "$CHECK_UPDATES" || return
  local age now
  age="$(update_cache_age)"
  now="$(date +%s 2>/dev/null || print "0")"
  [[ "$UPDATE_TTL_SECONDS" == <-> ]] || UPDATE_TTL_SECONDS=86400
  if [[ -z "$age" || $(( now - age )) -gt "$UPDATE_TTL_SECONDS" ]]; then
    "$0" check-updates >/dev/null 2>&1 &
  fi
}

ACTION="${1:-}"
case "$ACTION" in
  check-updates)
    write_update_cache
    exit 0
    ;;
  open)
    case "${2:-}" in
      codex-config) open_target "$CODEX_CONFIG" ;;
      claude-sessions) open_target "$CLAUDE_SESSIONS" ;;
      aichat-config) open_target "$AICHAT_CONFIG" ;;
      opencode-config) open_target "$OPENCODE_CONFIG" ;;
      swiftbar-folder) open_target "$SWIFTBAR_PLUGIN_DIR" ;;
      agentmemory-log) open_target "$AGENTMEMORY_LOG" ;;
      omlx-admin) open_target "$OMLX_ADMIN_URL" ;;
      omlx-chat) open_target "$OMLX_CHAT_URL" ;;
      agentmemory-viewer) open_target "$AGENTMEMORY_VIEWER_URL" ;;
      activity) open_app "Activity Monitor" ;;
    esac
    exit 0
    ;;
  refresh) exit 0 ;;
esac

shorten_path() {
  local p="${1:-}"
  [[ -z "$p" ]] && { print "-"; return; }
  p="${p/#$HOME/~}"
  if (( ${#p} > 74 )); then
    emit "…${p[-71,-1]}"
  else
    emit "$p"
  fi
}

shorten_text() {
  local s="${1:-}"
  local n="${2:-64}"
  s="${s//$'\n'/ }"
  if (( ${#s} > n )); then
    emit "${s[1,$((n-1))]}…"
  else
    emit "$s"
  fi
}

redact() {
  if ! have "$SED"; then
    builtin print -r -- "[command hidden: sed unavailable]"
    return
  fi
  builtin print -r -- "${1:-}" \
    | "$SED" -E \
      -e 's/(--api-key[= ]+)[^ ]+/\1****/Ig' \
      -e 's/([A-Z0-9_]*(API|TOKEN|KEY|SECRET)[A-Z0-9_]*=)[^ ]+/\1****/Ig' \
      -e 's/(Bearer )[A-Za-z0-9._~+\/=-]+/\1****/g' \
      -e 's/(github_pat_)[A-Za-z0-9_]+/\1****/g' \
      -e 's/(gh[opsu]_[A-Za-z0-9_]{8})[A-Za-z0-9_]+/\1****/g' \
      -e 's/(sk-[A-Za-z0-9_-]{8})[A-Za-z0-9_-]+/\1****/g' \
      -e 's/(sk-ant-[A-Za-z0-9_-]{8})[A-Za-z0-9_-]+/\1****/g' \
      -e 's/(AIza[0-9A-Za-z_-]{8})[0-9A-Za-z_-]+/\1****/g' \
      -e 's/(xox[baprs]-[A-Za-z0-9-]{8})[A-Za-z0-9-]+/\1****/g' \
      -e 's/(ctx7sk-)[A-Za-z0-9-]+/\1****/g'
}

cwd_for_pid() {
  local pid="$1"
  have "$LSOF" && have "$AWK" || return
  "$LSOF" -a -p "$pid" -d cwd -Fn 2>/dev/null | "$AWK" '/^n/ {sub(/^n/, ""); print; exit}'
}

is_listening() {
  have "$LSOF" || return 1
  "$LSOF" -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

cmd_version() {
  local bin="$1"
  command -v "$bin" >/dev/null 2>&1 || { print "-"; return; }
  if have "$SED"; then
    "$bin" --version 2>/dev/null | head -1 | "$SED" 's/[[:space:]]*$//'
  else
    "$bin" --version 2>/dev/null | head -1
  fi
}

toml_value() {
  local key="$1"
  local file="${2:-$CODEX_CONFIG}"
  have "$AWK" || return
  "$AWK" -F '"' -v k="$key" '$0 ~ "^" k "[[:space:]]*=" {print $2; exit}' "$file" 2>/dev/null
}

toml_section_value() {
  local section="$1"
  local key="$2"
  local file="${3:-$CODEX_CONFIG}"
  have "$AWK" || return
  "$AWK" -F '"' -v sec="[$section]" -v k="$key" '
    $0 == sec {inside=1; next}
    inside && $0 ~ /^\[/ {exit}
    inside && $0 ~ "^" k "[[:space:]]*=" {print $2; exit}
  ' "$file" 2>/dev/null
}

codex_profile_from_cmd() {
  local cmd="$1"
  have "$SED" || return
  if [[ "$cmd" == *"--profile "* ]]; then
    emit "$cmd" | "$SED" -E 's/^.*--profile[= ]([^ ]+).*$/\1/'
  elif [[ "$cmd" == *"-p "* ]]; then
    emit "$cmd" | "$SED" -E 's/^.*-p[= ]([^ ]+).*$/\1/'
  fi
}

codex_c_override() {
  local cmd="$1"
  local key="$2"
  have "$SED" || return
  emit "$cmd" | "$SED" -nE "s/^.*-c[[:space:]]+${key}=['\\\"]?([^ '\\\"]+).*$/\\1/p" | head -1
}

codex_model_for_cmd() {
  local cmd="$1"
  local profile model
  if [[ "$cmd" == *" -m "* ]]; then
    have "$SED" || return
    model="$(print "$cmd" | "$SED" -E 's/^.* -m[= ]([^ ]+).*$/\1/')"
    [[ -n "$model" ]] && { print "$model"; return; }
  fi
  if [[ "$cmd" == *" --model "* ]]; then
    have "$SED" || return
    model="$(print "$cmd" | "$SED" -E 's/^.* --model[= ]([^ ]+).*$/\1/')"
    [[ -n "$model" ]] && { print "$model"; return; }
  fi
  model="$(codex_c_override "$cmd" "model")"
  [[ -n "$model" ]] && { print "$model"; return; }
  profile="$(codex_profile_from_cmd "$cmd")"
  if [[ -n "$profile" ]]; then
    model="$(toml_section_value "profiles.$profile" "model")"
    [[ -n "$model" ]] && { print "$model"; return; }
  fi
  toml_value "model"
}

codex_provider_for_cmd() {
  local cmd="$1"
  local profile provider
  provider="$(codex_c_override "$cmd" "model_provider")"
  [[ -n "$provider" ]] && { print "$provider"; return; }
  profile="$(codex_profile_from_cmd "$cmd")"
  if [[ -n "$profile" ]]; then
    provider="$(toml_section_value "profiles.$profile" "model_provider")"
    [[ -n "$provider" ]] && { print "$provider"; return; }
  fi
  provider="$(toml_value "model_provider")"
  [[ -n "$provider" ]] && print "$provider" || print "openai"
}

codex_provider_url() {
  local provider="$1"
  [[ "$provider" == "openai" || -z "$provider" ]] && { print "OpenAI"; return; }
  local url
  url="$(toml_section_value "model_providers.$provider" "base_url")"
  [[ -n "$url" ]] && print "$url" || print "$provider"
}

aichat_current_model() {
  have "$AWK" || return
  "$AWK" '/^model:/ {sub(/^model:[[:space:]]*/, ""); print; exit}' "$AICHAT_CONFIG" 2>/dev/null
}

aichat_model_target() {
  local current="$1"
  local client="${current%%:*}"
  [[ "$current" == "$client" ]] && { print "-"; return; }
  have "$AWK" || return
  "$AWK" -v wanted="$client" '
    $1 == "name:" && $2 == wanted {inside=1}
    inside && $1 == "api_base:" {print $2; exit}
    inside && $1 == "-" && $2 == "type:" {inside=0}
  ' "$AICHAT_CONFIG" 2>/dev/null
}

claude_session_value() {
  local pid="$1"
  local key="$2"
  local f="$CLAUDE_SESSIONS/$pid.json"
  [[ -f "$f" ]] && have "$JQ" || return
  "$JQ" -r ".$key // empty" "$f" 2>/dev/null
}

endpoint_label() {
  local url="$1"
  case "$url" in
    *127.0.0.1:${OMLX_PORT}*|*localhost:${OMLX_PORT}*) print "oMLX :${OMLX_PORT}" ;;
    *127.0.0.1:${OLLAMA_PORT}*|*localhost:${OLLAMA_PORT}*) print "Ollama :${OLLAMA_PORT}" ;;
    *127.0.0.1:8093*|*localhost:8093*) print "DFlash/MLX :8093" ;;
    *ollama.com*) print "Ollama Cloud" ;;
    *openrouter.ai*) print "OpenRouter" ;;
    *generativelanguage.googleapis.com*|*google*) print "Gemini" ;;
    "") print "-" ;;
    *) print "$url" ;;
  esac
}

typeset -A PS_PPID PS_RSS PS_ETIME PS_CMD AGENT_NAME
typeset -a AGENT_PIDS MCP_PIDS BACKEND_PIDS

process_rows() {
  have "$PS" || return
  "$PS" -axo pid=,ppid=,rss=,etime=,command= 2>/dev/null \
    || "$PS" -eo pid=,ppid=,rss=,etime=,args= 2>/dev/null
}

while read -r pid ppid rss etime cmd; do
  [[ -z "${pid:-}" || -z "${cmd:-}" ]] && continue
  PS_PPID[$pid]="$ppid"
  PS_RSS[$pid]="$rss"
  PS_ETIME[$pid]="$etime"
  PS_CMD[$pid]="$cmd"

  # Main agent clients. Keep GUI apps out unless they are the CLI entrypoints.
  if [[ "$cmd" == *"agent-watch."*".sh"* ]]; then
    continue
  elif [[ "$cmd" == codex* || "$cmd" == */codex\ * ]]; then
    AGENT_NAME[$pid]="Codex"
    AGENT_PIDS+=("$pid")
  elif { [[ "$cmd" == claude* || "$cmd" == */claude\ * ]] && [[ "$cmd" != *"Claude.app"* ]]; }; then
    AGENT_NAME[$pid]="Claude Code"
    AGENT_PIDS+=("$pid")
  elif [[ "$cmd" == opencode* || "$cmd" == */opencode\ * || "$cmd" == *"/bin/opencode"* || "$cmd" == *"/.opencode"* || "$cmd" == *"opencode-ai"* ]]; then
    if [[ "$cmd" == node\ *"/bin/opencode"* ]]; then
      continue
    fi
    AGENT_NAME[$pid]="OpenCode"
    AGENT_PIDS+=("$pid")
  elif [[ "$cmd" == *"/gemini --acp"* || "$cmd" == *" gemini --acp"* ]]; then
    # Zed launches a tiny node shim which then launches the real Gemini ACP
    # node process. Count only the real child to avoid duplicate agent rows.
    [[ "$cmd" != *"--max-old-space-size="* ]] && continue
    AGENT_NAME[$pid]="Gemini ACP"
    AGENT_PIDS+=("$pid")
  elif [[ "$cmd" == aichat* || "$cmd" == */aichat\ * ]]; then
    AGENT_NAME[$pid]="aichat"
    AGENT_PIDS+=("$pid")
  elif [[ "$cmd" == aider* || "$cmd" == */aider\ * ]]; then
    AGENT_NAME[$pid]="Aider"
    AGENT_PIDS+=("$pid")
  elif [[ "$cmd" == *"agentmemory-mcp"* || "$cmd" == *"@agentmemory/mcp"* || "$cmd" == *"xcodebuildmcp"* || "$cmd" == *"context7-mcp"* || "$cmd" == *"mcp-server"* ]]; then
    MCP_PIDS+=("$pid")
  elif [[ "$cmd" == *"omlx serve"* || "$cmd" == *"ollama serve"* || "$cmd" == *"agentmemory"*"/dist/cli.mjs"* || "$cmd" == *".local/bin/iii --config"* ]]; then
    BACKEND_PIDS+=("$pid")
  fi
done < <(process_rows)

agent_owner_for_pid() {
  local cur="$1"
  local parent
  for _ in 1 2 3 4 5 6 7 8; do
    parent="${PS_PPID[$cur]:-}"
    [[ -z "$parent" || "$parent" == "0" || "$parent" == "1" ]] && break
    if [[ -n "${AGENT_NAME[$parent]:-}" ]]; then
      emit "${AGENT_NAME[$parent]} $parent"
      return
    fi
    cur="$parent"
  done
  emit "-"
}

child_count_for_agent() {
  local root="$1"
  local count=0
  local p owner
  for p in "${MCP_PIDS[@]}"; do
    owner="$(agent_owner_for_pid "$p")"
    [[ "$owner" == *" $root" ]] && (( count++ ))
  done
  emit "$count"
}

version_for_agent() {
  local name="$1"
  local pid="$2"
  case "$name" in
    "Codex") cmd_version codex | "$SED" 's/^codex-cli //' ;;
    "Claude Code")
      local v
      v="$(claude_session_value "$pid" "version")"
      [[ -n "$v" ]] && print "$v" || cmd_version claude | "$SED" 's/ (Claude Code)//'
      ;;
    "OpenCode") cmd_version opencode ;;
    "aichat") cmd_version aichat | "$SED" 's/^aichat //' ;;
    "Gemini ACP")
      local cmd="${PS_CMD[$pid]:-}"
      have "$SED" || { print "-"; return; }
      emit "$cmd" | "$SED" -nE 's/^.*node\/cache\/_npx\/([^\/]+)\/.*$/npx:\1/p' | head -1
      ;;
    *) print "-" ;;
  esac
}

model_for_agent() {
  local name="$1"
  local pid="$2"
  local cmd="${PS_CMD[$pid]:-}"
  case "$name" in
    "Codex")
      local model provider url
      model="$(codex_model_for_cmd "$cmd")"
      provider="$(codex_provider_for_cmd "$cmd")"
      url="$(codex_provider_url "$provider")"
      emit "${model:-unknown} · $(endpoint_label "$url")"
      ;;
    "Claude Code")
      emit "Claude Code cloud/default"
      ;;
    "OpenCode")
      if [[ -f "$OPENCODE_CONFIG" ]] && have "$JQ"; then
        local local_count
        local_count="$("$JQ" '[.provider // {} | to_entries[] | select((.value.options.baseURL // "") | test("127.0.0.1|localhost"))] | length' "$OPENCODE_CONFIG" 2>/dev/null)"
        [[ "${local_count:-0}" -gt 0 ]] && print "active model unknown · ${local_count} local provider(s) configured" || print "active model unknown"
      else
        emit "active model unknown"
      fi
      ;;
    "aichat")
      local model target
      model="$(aichat_current_model)"
      target="$(aichat_model_target "$model")"
      emit "${model:-unset} · $(endpoint_label "$target")"
      ;;
    "Gemini ACP")
      emit "Gemini ACP"
      ;;
    *) print "unknown" ;;
  esac
}

status_for_agent() {
  local name="$1"
  local pid="$2"
  if [[ "$name" == "Claude Code" ]]; then
    local s
    s="$(claude_session_value "$pid" "status")"
    [[ -n "$s" ]] && { print "$s"; return; }
  fi
  emit "running"
}

agent_color() {
  local s="$1"
  case "$s" in
    busy) print "#ff9800" ;;
    idle) print "#4caf50" ;;
    *) print "#5aa9ff" ;;
  esac
}

format_rss_mb() {
  local kb="${1:-0}"
  printf "%.1f" "$(( kb / 1024.0 ))" 2>/dev/null || print "0.0"
}

mcp_label_for_cmd() {
  local cmd="$1"
  [[ "$cmd" == *"agentmemory-mcp"* || "$cmd" == *"@agentmemory/mcp"* ]] && { print "AgentMemory MCP"; return; }
  [[ "$cmd" == *"xcodebuildmcp"* ]] && { print "XcodeBuild MCP"; return; }
  [[ "$cmd" == *"context7-mcp"* ]] && { print "Context7 MCP"; return; }
  print "MCP/helper"
}

agentmemory_detected() {
  is_listening "$AGENTMEMORY_PORT" && return 0
  local pid cmd
  for pid in "${MCP_PIDS[@]}" "${BACKEND_PIDS[@]}"; do
    cmd="${PS_CMD[$pid]:-}"
    [[ "$cmd" == *"agentmemory"* || "$cmd" == *"@agentmemory/mcp"* ]] && return 0
  done
  return 1
}

print_helper_summary_rows() {
  local pid label owner key rss
  typeset -A counts rss_by_label owner_counts owner_rss
  for pid in "${MCP_PIDS[@]}"; do
    label="$(mcp_label_for_cmd "${PS_CMD[$pid]:-}")"
    owner="$(agent_owner_for_pid "$pid")"
    [[ "$owner" == "-" ]] && owner="unowned"
    key="${label}|${owner}"
    counts[$label]=$(( ${counts[$label]:-0} + 1 ))
    owner_counts[$key]=$(( ${owner_counts[$key]:-0} + 1 ))
    rss="${PS_RSS[$pid]:-0}"
    rss_by_label[$label]=$(( ${rss_by_label[$label]:-0} + rss ))
    owner_rss[$key]=$(( ${owner_rss[$key]:-0} + rss ))
  done
  for label in "${(@k)counts}"; do
    emit "--${label} · ${counts[$label]} process(es) · $(format_rss_mb "${rss_by_label[$label]:-0}") MB RSS | font=Menlo"
    for key in "${(@k)owner_counts}"; do
      [[ "$key" == "$label|"* ]] || continue
      owner="${key#*|}"
      emit "----owner ${owner} · ${owner_counts[$key]} process(es) · $(format_rss_mb "${owner_rss[$key]:-0}") MB RSS | font=Menlo"
    done
  done
}

clean_version_for_tool() {
  local tool="$1"
  local version
  version="$(cmd_version "$tool")"
  if have "$SED"; then
    case "$tool" in
      codex) emit "$version" | "$SED" 's/^codex-cli //' ;;
      claude) emit "$version" | "$SED" 's/ (Claude Code)//' ;;
      aichat) emit "$version" | "$SED" 's/^aichat //' ;;
      *) emit "$version" ;;
    esac
  else
    emit "$version"
  fi
}

print_installed_cli_rows() {
  local any=0 name bin update_key latest version tool_path update_status color
  for spec in \
    "Codex|codex|codex" \
    "Claude Code|claude|claude" \
    "OpenCode|opencode|opencode" \
    "Gemini CLI|gemini|gemini" \
    "Aider|aider|" \
    "aichat|aichat|"; do
    name="${spec%%|*}"
    spec="${spec#*|}"
    bin="${spec%%|*}"
    update_key="${spec#*|}"
    command -v "$bin" >/dev/null 2>&1 || continue
    any=1
    version="$(clean_version_for_tool "$bin")"
    tool_path="$(command -v "$bin" 2>/dev/null)"
    latest=""
    [[ -n "$update_key" ]] && latest="$(cached_latest_version "$update_key")"
    update_status="installed"
    color="#5aa9ff"
    if [[ -n "$latest" ]]; then
      if [[ "$version" == *"$latest"* ]]; then
        update_status="current"
        color="#4caf50"
      else
        update_status="latest ${latest}"
        color="#ff9800"
      fi
    fi
    emit "--${name} · ${version:-version unknown} · ${update_status} | color=${color}"
    emit "----Path: $(shorten_path "$tool_path") | font=Menlo"
  done
  (( any == 0 )) && emit "--No known coding CLIs found on PATH | color=gray"
}

omlx_status_line() {
  if ! is_listening "$OMLX_PORT"; then
    emit "oMLX :${OMLX_PORT} - down"
    return
  fi
  local key="" json loaded total
  have "$CURL" || { emit "oMLX :${OMLX_PORT} - up, curl unavailable"; return; }
  key="$OMLX_API_KEY"
  [[ -z "$key" && -n "$OMLX_KEY_FILE" && -f "$OMLX_KEY_FILE" ]] && key="$(cat "$OMLX_KEY_FILE" 2>/dev/null)"
  if [[ -n "$key" ]]; then
    json="$("$CURL" -s --max-time 2 -H "Authorization: Bearer $key" "$OMLX_URL/v1/models/status" 2>/dev/null)"
  else
    json="$("$CURL" -s --max-time 2 "$OMLX_URL/v1/models/status" 2>/dev/null)"
  fi
  if have "$JQ" && print "$json" | "$JQ" -e '.models' >/dev/null 2>&1; then
    loaded="$(print "$json" | "$JQ" '[.models[] | select(.loaded)] | length')"
    total="$(print "$json" | "$JQ" '.models | length')"
    emit "oMLX :${OMLX_PORT} - ${loaded}/${total} loaded"
  else
    emit "oMLX :${OMLX_PORT} - up, auth/status limited"
  fi
}

omlx_loaded_rows() {
  local key="" json
  have "$CURL" && have "$JQ" || return
  key="$OMLX_API_KEY"
  [[ -z "$key" && -n "$OMLX_KEY_FILE" && -f "$OMLX_KEY_FILE" ]] && key="$(cat "$OMLX_KEY_FILE" 2>/dev/null)"
  if [[ -n "$key" ]]; then
    json="$("$CURL" -s --max-time 2 -H "Authorization: Bearer $key" "$OMLX_URL/v1/models/status" 2>/dev/null)"
  else
    json="$("$CURL" -s --max-time 2 "$OMLX_URL/v1/models/status" 2>/dev/null)"
  fi
  emit "$json" | "$JQ" -r '.models[]? | select(.loaded) | [.id, .engine_type, .max_context_window, .estimated_size] | @tsv' 2>/dev/null \
  | while IFS=$'\t' read -r id engine ctx size; do
    local short gb ctxk
    if have "$SED"; then
      short="$(print "$id" | "$SED" 's/^.*--//; s/-MLX-.*$//; s/-mlx-.*$//')"
    else
      short="$id"
    fi
    gb="$(printf "%.1f" "$(( size / 1073741824.0 ))" 2>/dev/null)"
    ctxk="$(( ctx / 1024 ))K"
    emit "--✓ $(shorten_text "$short" 58) · ${engine} · ${gb}GB · ${ctxk} | color=#4caf50"
  done
}

omlx_first_loaded_model() {
  local key="" json
  have "$CURL" && have "$JQ" || return
  is_listening "$OMLX_PORT" || return
  key="$OMLX_API_KEY"
  [[ -z "$key" && -n "$OMLX_KEY_FILE" && -f "$OMLX_KEY_FILE" ]] && key="$(cat "$OMLX_KEY_FILE" 2>/dev/null)"
  if [[ -n "$key" ]]; then
    json="$("$CURL" -s --max-time 1 -H "Authorization: Bearer $key" "$OMLX_URL/v1/models/status" 2>/dev/null)"
  else
    json="$("$CURL" -s --max-time 1 "$OMLX_URL/v1/models/status" 2>/dev/null)"
  fi
  emit "$json" | "$JQ" -r '.models[]? | select(.loaded) | .id' 2>/dev/null | head -1
}

ollama_status_line() {
  if ! is_listening "$OLLAMA_PORT"; then
    emit "Ollama :${OLLAMA_PORT} - down"
    return
  fi
  local json count
  have "$CURL" && have "$JQ" || { emit "Ollama :${OLLAMA_PORT} - up, status limited"; return; }
  json="$("$CURL" -s --max-time 2 "$OLLAMA_URL/api/ps" 2>/dev/null)"
  count="$(print "$json" | "$JQ" '.models | length' 2>/dev/null)"
  emit "Ollama :${OLLAMA_PORT} - ${count:-?} loaded"
}

ollama_loaded_rows() {
  local json
  have "$CURL" && have "$JQ" || return
  json="$("$CURL" -s --max-time 2 "$OLLAMA_URL/api/ps" 2>/dev/null)"
  emit "$json" | "$JQ" -r '.models[]? | [.name, .details.parameter_size, .details.quantization_level, .context_length, .size_vram] | @tsv' 2>/dev/null \
  | while IFS=$'\t' read -r name params quant ctx vram; do
    local gb
    gb="$(printf "%.1f" "$(( vram / 1073741824.0 ))" 2>/dev/null)"
    emit "--✓ ${name} · ${params} · ${quant} · ctx ${ctx} · ${gb}GB | color=#4caf50"
  done
}

agentmemory_status_line() {
  local json version health_status workers
  have "$CURL" && have "$JQ" || { emit "AgentMemory :${AGENTMEMORY_PORT} - status unavailable"; return; }
  json="$("$CURL" -s --max-time 2 "$AGENTMEMORY_URL/agentmemory/health" 2>/dev/null)"
  if print "$json" | "$JQ" -e '.version' >/dev/null 2>&1; then
    version="$(print "$json" | "$JQ" -r '.version')"
    health_status="$(print "$json" | "$JQ" -r '.status')"
    workers="$(print "$json" | "$JQ" -r '.health.workers | length')"
    emit "AgentMemory :${AGENTMEMORY_PORT} - ${health_status} v${version}, ${workers} worker"
  else
    emit "AgentMemory :${AGENTMEMORY_PORT} - down/unknown"
  fi
}

open_ports_rows() {
  have "$LSOF" && have "$AWK" || return
  "$LSOF" -nP -iTCP -sTCP:LISTEN 2>/dev/null \
    | "$AWK" -v ports="$INTERESTING_PORTS" '
      BEGIN {
        gsub(/,/, "|", ports)
        pattern = ":(" ports ")$"
      }
      NR > 1 && ($9 ~ pattern) {print $1 "|" $2 "|" $9}
    ' \
    | while IFS='|' read -r proc pid addr; do
      emit "--${addr} · ${proc} pid ${pid} | font=Menlo"
    done
}

agent_count="${#AGENT_PIDS[@]}"
mcp_count="${#MCP_PIDS[@]}"
local_backend_count=0
is_listening "$OMLX_PORT" && (( local_backend_count++ ))
is_listening "$OLLAMA_PORT" && (( local_backend_count++ ))
agentmemory_detected && (( local_backend_count++ ))
maybe_refresh_update_cache

first_model=""
if is_listening "$OLLAMA_PORT" && have "$CURL" && have "$JQ"; then
  first_model="$("$CURL" -s --max-time 1 "$OLLAMA_URL/api/ps" 2>/dev/null | "$JQ" -r '.models[0].name // empty' 2>/dev/null)"
fi
[[ -z "$first_model" ]] && first_model="$(omlx_first_loaded_model)"
if [[ -z "$first_model" ]] && is_listening "$OMLX_PORT"; then
  first_model="oMLX up"
fi
first_model="$(shorten_text "$first_model" 18)"

emit "🤖 ${agent_count} agents · ${first_model:-no model}"
emit "---"

emit "Agent Clients"
if (( agent_count == 0 )); then
  emit "--No known CLI agents detected | color=gray"
fi

for pid in "${AGENT_PIDS[@]}"; do
  name="${AGENT_NAME[$pid]}"
  etime="${PS_ETIME[$pid]:-?}"
  cmd="${PS_CMD[$pid]:-}"
  cwd="$(cwd_for_pid "$pid")"
  version="$(version_for_agent "$name" "$pid")"
  model="$(model_for_agent "$name" "$pid")"
  agent_status="$(status_for_agent "$name" "$pid")"
  color="$(agent_color "$agent_status")"
  helpers="$(child_count_for_agent "$pid")"
  emit "--${name} pid ${pid} · ${agent_status} · ${etime} | color=${color}"
  emit "----Model/target: $(shorten_text "$model" 86) | font=Menlo"
  emit "----Version: ${version:-unknown} | font=Menlo"
  emit "----Folder: $(shorten_path "$cwd") | font=Menlo"
  emit "----MCP/helper children: ${helpers} | font=Menlo"
  if [[ "$SHOW_COMMANDS" == "1" || "$SHOW_COMMANDS" == "true" ]]; then
    emit "----Command: $(shorten_text "$(redact "$cmd")" 110) | font=Menlo"
  fi
done

emit "---"
emit "Local LLM / Memory Backends"
if (( local_backend_count == 0 )); then
  emit "--No known local backends detected | color=gray"
else
  if is_listening "$OMLX_PORT"; then
    emit "--$(omlx_status_line)"
    omlx_loaded_rows
  fi
  if is_listening "$OLLAMA_PORT"; then
    emit "--$(ollama_status_line)"
    ollama_loaded_rows
  fi
  if agentmemory_detected; then
    emit "--$(agentmemory_status_line)"
  fi
fi

emit "---"
emit "MCP / Helper Processes"
if (( mcp_count == 0 )); then
  emit "--No MCP helpers detected | color=gray"
else
  if truthy "$SHOW_HELPERS"; then
    for pid in "${MCP_PIDS[@]}"; do
      cmd="${PS_CMD[$pid]:-}"
      owner="$(agent_owner_for_pid "$pid")"
      label="$(mcp_label_for_cmd "$cmd")"
      emit "--${label} pid ${pid} · owner ${owner} · ${PS_ETIME[$pid]:-?} · $(format_rss_mb "${PS_RSS[$pid]:-0}") MB RSS"
      if truthy "$SHOW_COMMANDS"; then
        emit "----Command: $(shorten_text "$(redact "$cmd")" 110) | font=Menlo"
      fi
    done
  else
    print_helper_summary_rows
    emit "--Show individual helper processes | bash=$0 param1=refresh terminal=false refresh=true"
    emit "----Set AGENTWATCH_SHOW_HELPERS=1 for per-process debug output | color=gray"
  fi
fi

emit "---"
emit "Installed Coding CLIs"
print_installed_cli_rows
if truthy "$CHECK_UPDATES"; then
  cache_age="$(update_cache_age)"
  if [[ -n "$cache_age" ]]; then
    emit "--Refresh update cache | bash=$0 param1=check-updates terminal=false refresh=true"
  else
    emit "--Check updates now | bash=$0 param1=check-updates terminal=false refresh=true"
  fi
else
  emit "--Update checks disabled | color=gray"
fi

if [[ -n "$INTERESTING_PORTS" ]]; then
  emit "---"
  emit "Interesting Listening Ports"
  open_ports_rows
fi

emit "---"
emit "Actions"
if truthy "$SHOW_CONFIG_ACTIONS"; then
  [[ -f "$CODEX_CONFIG" ]] && emit "--Open Codex config | bash=$0 param1=open param2=codex-config terminal=false"
  [[ -d "$CLAUDE_SESSIONS" ]] && emit "--Open Claude session metadata | bash=$0 param1=open param2=claude-sessions terminal=false"
  [[ -f "$AICHAT_CONFIG" ]] && command -v aichat >/dev/null 2>&1 && emit "--Open aichat config | bash=$0 param1=open param2=aichat-config terminal=false"
  [[ -f "$OPENCODE_CONFIG" ]] && command -v opencode >/dev/null 2>&1 && emit "--Open OpenCode config | bash=$0 param1=open param2=opencode-config terminal=false"
fi
if truthy "$SHOW_BACKEND_ACTIONS"; then
  if is_listening "$OMLX_PORT"; then
    emit "--Open oMLX admin | bash=$0 param1=open param2=omlx-admin terminal=false"
    emit "--Open oMLX chat | bash=$0 param1=open param2=omlx-chat terminal=false"
  fi
  if agentmemory_detected; then
    emit "--Open AgentMemory viewer | bash=$0 param1=open param2=agentmemory-viewer terminal=false"
    [[ -f "$AGENTMEMORY_LOG" ]] && emit "--Open AgentMemory log | bash=$0 param1=open param2=agentmemory-log terminal=false"
  fi
fi
[[ -d "$SWIFTBAR_PLUGIN_DIR" ]] && emit "--Open SwiftBar plugin folder | bash=$0 param1=open param2=swiftbar-folder terminal=false"
if command -v open >/dev/null 2>&1; then
  emit "--Open Activity Monitor | bash=$0 param1=open param2=activity terminal=false"
fi
emit "Refresh | refresh=true"

exit 0
