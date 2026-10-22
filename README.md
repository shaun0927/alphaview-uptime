# alphaview-uptime

External availability probe for https://www.alphaview.kr, independent of the origin host.

- `.github/workflows/probe.yml` runs every 5 minutes (GitHub schedules are best-effort; gaps of a few minutes are normal).
- Targets (public pages only): `/`, `/api/health`, `/ticker/NVDA`, `/news/44725` on https://www.alphaview.kr.
- A target counts as down only after 3 failed attempts 10 s apart.
- Results: `log/YYYY-MM.csv` on the `data` branch (`ts_utc,target,http_code,seconds,state,attempts`).
- Alerting: an issue labelled `outage` is opened on failure, commented while down, and closed on recovery (GitHub notifies repo watchers by email).
- No secrets: only the built-in `GITHUB_TOKEN`.

Availability for a period = rows with `state=up` / all rows, per target.
