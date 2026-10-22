#!/usr/bin/env bash
# Probes public AlphaView endpoints from GitHub's network (independent of the origin host).
# A target fails only if 3 attempts (10 s apart) all fail: non-2xx/3xx, timeout, or TLS error.
set -u
TARGETS=(
  "home|https://www.alphaview.kr/"
  "api_health|https://www.alphaview.kr/api/health"
  "ticker|https://www.alphaview.kr/ticker/NVDA"
  "news|https://www.alphaview.kr/news/44725"
)
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ); overall=ok; rows=""
for t in "${TARGETS[@]}"; do
  name=${t%%|*}; url=${t#*|}; code=000; secs=0; ok=0
  for attempt in 1 2 3; do
    out=$(curl -sS -o /dev/null -w '%{http_code} %{time_total}' --max-time 20 -A 'alphaview-uptime-probe/1 (+github actions)' "$url?probe=$(date +%s)" 2>/dev/null || echo "000 20")
    code=${out%% *}; secs=${out#* }
    case $code in 2*|3*) ok=1; break;; esac
    [ $attempt -lt 3 ] && sleep 10
  done
  [ $ok = 1 ] || overall=down
  rows="${rows}${ts},${name},${code},${secs},$([ $ok = 1 ] && echo up || echo down),${attempt}\n"
  echo "$name $url -> $code ${secs}s attempts=$attempt $([ $ok = 1 ] && echo UP || echo DOWN)"
done
printf "%b" "$rows" > /tmp/probe_rows.csv
echo "$overall" > /tmp/probe_overall
echo "overall=$overall" >> "$GITHUB_OUTPUT"
