#!/usr/bin/env bash
# One open issue labelled `outage` while any target is down; closed automatically on recovery.
set -u
state=$(cat /tmp/probe_overall 2>/dev/null || echo down)
gh label create outage --color B60205 --description "AlphaView external probe failure" -R "$GITHUB_REPOSITORY" >/dev/null 2>&1 || true
open=$(gh issue list -R "$GITHUB_REPOSITORY" --label outage --state open --json number --jq '.[0].number' 2>/dev/null)
detail=$(sed 's/^/    /' /tmp/probe_rows.csv 2>/dev/null)
run="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
if [ "$state" = down ]; then
  if [ -z "$open" ]; then
    gh issue create -R "$GITHUB_REPOSITORY" --label outage --title "AlphaView DOWN $(date -u +%Y-%m-%dT%H:%MZ)" \
      --body "External probe failed after 3 attempts.

    ts_utc,target,http_code,seconds,state,attempts
${detail}

Run: ${run}"
  else
    gh issue comment "$open" -R "$GITHUB_REPOSITORY" --body "Still down at $(date -u +%H:%MZ). ${run}
${detail}" >/dev/null
  fi
elif [ -n "$open" ]; then
  gh issue close "$open" -R "$GITHUB_REPOSITORY" --comment "Recovered at $(date -u +%Y-%m-%dT%H:%MZ). ${run}" >/dev/null
fi
