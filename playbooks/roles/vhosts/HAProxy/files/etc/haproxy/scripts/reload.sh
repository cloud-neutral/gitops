#!/usr/bin/env bash
set -euo pipefail

CONFIG="/etc/haproxy/haproxy.cfg"
PIDFILE="/var/run/haproxy.pid"
HAPROXY_BIN="${HAPROXY_BIN:-/usr/sbin/haproxy}"
SYSTEMCTL_BIN="${SYSTEMCTL_BIN:-/bin/systemctl}"

# Validate configuration before applying
if ! "${HAPROXY_BIN}" -c -f "${CONFIG}"; then
  echo "HAProxy configuration validation failed" >&2
  exit 1
fi

# Reload HAProxy gracefully
if command -v "${SYSTEMCTL_BIN}" >/dev/null 2>&1; then
  exec "${SYSTEMCTL_BIN}" reload haproxy
else
  if [[ -r "${PIDFILE}" ]]; then
    exec "${HAPROXY_BIN}" -f "${CONFIG}" -sf "$(cat "${PIDFILE}")"
  else
    exec "${HAPROXY_BIN}" -f "${CONFIG}"
  fi
fi
