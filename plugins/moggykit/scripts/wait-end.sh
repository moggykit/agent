#!/usr/bin/env bash
# Moggykit: how long did you wait? One line after 3 minutes or more, at most once every 20 minutes.
# Quiet on any failure. Counts stay on this machine. Nothing is sent anywhere.
set -u
command -v node >/dev/null || exit 0
dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}/moggykit"
min="${MOGGYKIT_WAIT_SECONDS:-180}"      # show the line from this many seconds of waiting
gap="${MOGGYKIT_WAIT_GAP_SECONDS:-1200}" # never more than one line in this many seconds

id=$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).session_id||""))}catch{}})') || exit 0
[ -n "$id" ] && [ -s "$dir/start-$id.txt" ] || exit 0

now=$(date +%s)
start=$(cat "$dir/start-$id.txt")
rm -f "$dir/start-$id.txt"
secs=$((now - start))
[ "$secs" -ge 0 ] || exit 0

# every run goes in today's log, for T6 Shift Report tomorrow
echo "$now,$secs" >> "$dir/runs-$(date -u +%Y-%m-%d).log"

[ "$secs" -ge "$min" ] || exit 0
last=0; [ -s "$dir/last-line.txt" ] && last=$(cat "$dir/last-line.txt")
[ $((now - last)) -ge "$gap" ] || exit 0

name="The cat on duty"
cache="$dir/cat-on-duty-$(date -u +%Y-%m-%d).txt"
[ -s "$cache" ] && IFS='|' read -r name _ _ < "$cache"

if [ "$secs" -ge 60 ]; then took="$((secs / 60))m $((secs % 60))s"; else took="${secs}s"; fi
echo "$now" > "$dir/last-line.txt"
endings=("slept through it" "did not notice" "was asleep the whole time" "washed a paw and went back to sleep" "opened one eye" "kept watch (allegedly)" "supervised from a sunny spot" "would like it known that this was fine")
if [ -s "$dir/first-line-shown.txt" ]; then ending="${endings[RANDOM % ${#endings[@]}]}"; else ending="napped through it"; echo 1 > "$dir/first-line-shown.txt"; fi
printf '{"systemMessage": "🐈 That took %s. %s %s."}\n' "$took" "$name" "$ending"
