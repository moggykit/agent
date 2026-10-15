#!/usr/bin/env bash
# Moggykit: remember when this prompt was sent. Quiet on any failure. Nothing is sent anywhere.
set -u
command -v node >/dev/null || exit 0
dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}/moggykit"
mkdir -p "$dir" 2>/dev/null || exit 0
id=$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).session_id||""))}catch{}})') || exit 0
[ -n "$id" ] || exit 0
date +%s > "$dir/start-$id.txt"
exit 0
