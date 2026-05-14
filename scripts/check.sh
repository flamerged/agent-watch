#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
PLUGIN="$ROOT/bin/agent-watch.30s.sh"

zsh -n "$PLUGIN"

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
  'AGENTWATCH_OMLX_URL' \
  'AGENTWATCH_OLLAMA_URL' \
  'AGENTWATCH_AGENTMEMORY_URL' \
  'AGENTWATCH_SHOW_COMMANDS' \
  'AGENTWATCH_INTERESTING_PORTS'; do
  grep -q "<xbar.var>.*$var" "$PLUGIN"
done

output="$(
  AGENTWATCH_SHOW_COMMANDS=0 \
  AGENTWATCH_OMLX_URL=http://127.0.0.1:1 \
  AGENTWATCH_OLLAMA_URL=http://127.0.0.1:1 \
  AGENTWATCH_AGENTMEMORY_URL=http://127.0.0.1:1 \
  "$PLUGIN"
)"

print -r -- "$output" | grep -q '^Agent Clients$'
print -r -- "$output" | grep -q '^Local LLM / Memory Backends$'
if print -r -- "$output" | grep -q 'Command:'; then
  print -u2 "command lines should be hidden by default"
  exit 1
fi

print "checks passed"
