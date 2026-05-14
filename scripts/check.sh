#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
PLUGIN="$ROOT/bin/agent-watch.30s.sh"

zsh -n "$PLUGIN"
zsh -n "$ROOT/scripts/install-swiftbar.sh"
zsh -n "$ROOT/scripts/install-dev-swiftbar.sh"
bash -n "$ROOT/scripts/auto-release.sh"

for tag in \
  '<xbar.title>' \
  '<xbar.version>' \
  '<xbar.author>' \
  '<xbar.author.github>' \
  '<xbar.desc>' \
  '<xbar.dependencies>' \
  '<xbar.abouturl>' \
  '<swiftbar.title>'; do
  grep -q "$tag" "$PLUGIN"
done

for var in \
  'AGENTWATCH_CONFIG_FILE' \
  'AGENTWATCH_OMLX_URL' \
  'AGENTWATCH_OLLAMA_URL' \
  'AGENTWATCH_SHOW_COMMANDS' \
  'AGENTWATCH_SHOW_HELPERS' \
  'AGENTWATCH_CHECK_UPDATES' \
  'AGENTWATCH_UPDATE_TTL_SECONDS' \
  'AGENTWATCH_SHOW_CONFIG_ACTIONS' \
  'AGENTWATCH_SHOW_BACKEND_ACTIONS' \
  'AGENTWATCH_REPO_DIR' \
  'AGENTWATCH_REPO_URL' \
  'AGENTWATCH_RELEASE_ASSET_URL' \
  'AGENTWATCH_UPDATE_LOG' \
  'AGENTWATCH_INTERESTING_PORTS'; do
  grep -q "<xbar.var>.*$var" "$PLUGIN"
done

output="$(
  AGENTWATCH_SHOW_COMMANDS=0 \
  AGENTWATCH_CONFIG_FILE="$(mktemp)" \
  AGENTWATCH_CHECK_UPDATES=0 \
  AGENTWATCH_OMLX_URL=http://127.0.0.1:1 \
  AGENTWATCH_OLLAMA_URL=http://127.0.0.1:1 \
  AGENTWATCH_AGENTMEMORY_URL=http://127.0.0.1:1 \
  "$PLUGIN"
)"

print -r -- "$output" | grep -q '^Agent Clients$'
print -r -- "$output" | grep -q '^Local LLM / Memory Backends$'
print -r -- "$output" | grep -q '^Agent Watch$'
print -r -- "$output" | grep -q 'Open config file'
if print -r -- "$output" | grep -q 'Command:'; then
  print -u2 "command lines should be hidden by default"
  exit 1
fi

config_file="$(mktemp)"
print -r -- 'AGENTWATCH_INTERESTING_PORTS=54321' > "$config_file"
config_output="$(
  AGENTWATCH_CONFIG_FILE="$config_file" \
  AGENTWATCH_CHECK_UPDATES=0 \
  AGENTWATCH_OMLX_URL=http://127.0.0.1:1 \
  AGENTWATCH_OLLAMA_URL=http://127.0.0.1:1 \
  AGENTWATCH_AGENTMEMORY_URL=http://127.0.0.1:1 \
  "$PLUGIN"
)"
print -r -- "$config_output" | grep -q 'Filter: 54321'

print "checks passed"
