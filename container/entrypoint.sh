#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

mkdir -p -- "${HOME:-/tmp/rekon-home}"

case "${1:-}" in
  rekon)
    shift
    ;;
  shell)
    shift
    exec /bin/bash "$@"
    ;;
  bash|/bin/bash|sh|/bin/sh)
    exec "$@"
    ;;
esac

exec /opt/rekon/rekon.sh "$@"
