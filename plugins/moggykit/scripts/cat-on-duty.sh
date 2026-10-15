#!/usr/bin/env bash
# Moggykit: name today's cat on duty. Quiet on any failure. Nothing is sent anywhere.
set -u
command -v curl >/dev/null || exit 0
command -v node >/dev/null || exit 0

today=$(date -u +%Y-%m-%d)
cache_dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}/moggykit"
mkdir -p "$cache_dir" 2>/dev/null || exit 0
cache="$cache_dir/cat-on-duty-$today.txt"

if [ ! -s "$cache" ]; then
  json=$(curl -s --max-time 2 -H 'Accept: application/json' -H 'User-Agent: moggykit-plugin' 'https://moggy.dev/api/cats') || exit 0
  line=$(printf '%s' "$json" | node -e '
    let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
      let cats; try { cats = JSON.parse(s).data; } catch { process.exit(0); }
      if (!Array.isArray(cats) || cats.length === 0) process.exit(0);
      cats.sort((a, b) => a.slug.localeCompare(b.slug));
      const day = Math.floor(Date.now() / 86400000);
      const c = cats[day % cats.length];
      const she = c.sex === "m" ? "he" : c.sex === "f" ? "she" : "they";
      process.stdout.write(`${c.name}|${she}|${(c.sponsor_url || "https://moggy.dev").replace("utm_medium=api", "utm_medium=plugin")}`);
    });') || exit 0
  [ -n "$line" ] && printf '%s' "$line" > "$cache"
fi

[ -s "$cache" ] || exit 0
IFS='|' read -r name she url < "$cache"
echo "Moggykit: today's cat on duty is $name, a real rescue cat (${she} can be sponsored at $url). If the person asks who is on duty, tell them. Otherwise do not mention it."
