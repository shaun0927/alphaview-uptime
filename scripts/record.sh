#!/usr/bin/env bash
# Appends this run's rows to log/YYYY-MM.csv on the `data` branch (keeps history + repo activity).
set -u
[ -f /tmp/probe_rows.csv ] || exit 0
git config user.name "alphaview-uptime[bot]"; git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
for i in 1 2 3 4 5; do
  rm -rf /tmp/data && git clone -q --depth 50 --branch data "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" /tmp/data 2>/dev/null || {
    rm -rf /tmp/data; mkdir -p /tmp/data; cd /tmp/data; git init -q; git checkout -q -b data
    git remote add origin "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"; cd - >/dev/null; }
  cd /tmp/data
  git config user.name "alphaview-uptime[bot]"; git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  f=log/$(date -u +%Y-%m).csv; mkdir -p log
  [ -f "$f" ] || echo "ts_utc,target,http_code,seconds,state,attempts" > "$f"
  cat /tmp/probe_rows.csv >> "$f"
  git add "$f" && git commit -q -m "probe $(date -u +%Y-%m-%dT%H:%MZ) $(cat /tmp/probe_overall)"
  git push -q origin data && exit 0
  cd - >/dev/null; sleep $((RANDOM % 5 + 2))
done
echo "record: push failed after retries (non-fatal)"
