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
    out=$(curl -sS -D /tmp/probe_h -o /dev/null -w '%{http_code} %{time_total}' --max-time 20 -A 'alphaview-uptime-probe/1 (+github actions)' "$url?probe=$(date +%s)" 2>/dev/null || echo "000 20")
    code=${out%% *}; secs=${out#* }
    case $code in 2*|3*) ok=1; break;; esac
    # Cloudflare bot protection challenges datacenter IPs (GitHub runners) on HTML pages: the edge is up
    # and answering, so this is recorded as 'challenged' (not an outage). /api/health stays the end-to-end check.
    if [ "$code" = 403 ] && grep -qi '^cf-mitigated:' /tmp/probe_h 2>/dev/null; then ok=2; break; fi
    [ $attempt -lt 3 ] && sleep 10
  done
  state=down; [ $ok = 1 ] && state=up; [ $ok = 2 ] && state=challenged
  [ $state = down ] && overall=down
  rows="${rows}${ts},${name},${code},${secs},${state},${attempt}\n"
  echo "$name $url -> $code ${secs}s attempts=$attempt $state"
done
printf "%b" "$rows" > /tmp/probe_rows.csv
echo "$overall" > /tmp/probe_overall
echo "overall=$overall" >> "$GITHUB_OUTPUT"
