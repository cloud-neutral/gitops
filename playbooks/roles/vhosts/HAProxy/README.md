# HAProxy Role

This role provisions a thin, include-only HAProxy configuration tree under `/etc/haproxy/`. It follows a map-driven SNI routing strategy so that new hostnames can be added without touching the frontend logic.

## Layout
```
/etc/haproxy/
├── haproxy.cfg              # Main entry point (kept thin)
├── global.cfg               # global + defaults
├── frontends/
│   ├── fe_443.cfg
│   └── fe_stats.cfg
├── backends/
│   ├── console/
│   │   ├── bk_cn.cfg
│   │   └── bk_global.cfg
│   ├── xray/
│   │   ├── bk_xray_jp.cfg
│   │   ├── bk_xray_sg.cfg
│   │   └── bk_xray_hk.cfg
│   └── fallback/
│       └── bk_blackhole.cfg
├── maps/
│   ├── sni.map
│   └── sni_backend.map
├── certs/                   # For HTTP/TLS termination if needed
├── scripts/
│   └── reload.sh
└── logs/
```

### Main configuration (`haproxy.cfg`)
- Includes `global.cfg` for shared defaults.
- Includes all frontends and recursively includes business backends.
- Contains no business logic to keep reloads predictable.

### Global/defaults (`global.cfg`)
Applies TCP defaults and keeps per-node tuning minimal. HK/JP can adjust `maxconn` per-node if needed.

### Frontends
- `fe_443.cfg` performs TLS inspection and routes via the SNI map (`maps/sni_backend.map`), falling back to `bk_blackhole`.
- `fe_stats.cfg` exposes the HAProxy stats UI on `:8404`.

### Maps
- `maps/sni_backend.map` maps SNI hosts to backends; adding a domain means adding a single line.
- `maps/sni.map` documents the expected format when TLS termination is required.

### Backends
Business backends are grouped by domain family (console/xray/fallback) with TCP health checks and consistent timings. The fallback backend intentionally blackholes unmatched traffic.

### Reload helper
`scripts/reload.sh` validates the configuration and reloads HAProxy gracefully (preferring `systemctl` when present).

## Usage
1. Include the role in a play targeting your HAProxy hosts.
2. Update `maps/sni_backend.map` with the desired hostname-to-backend mapping.
3. Adjust backend server endpoints per site; keep the directory layout identical across regions.
4. Run the play to copy the configuration tree and trigger a graceful reload via the handler.
