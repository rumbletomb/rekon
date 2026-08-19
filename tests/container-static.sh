#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=container/versions.env
source "$PROJECT_ROOT/container/versions.env"

fail() {
  printf 'FAIL container: %s\n' "$*" >&2
  exit 1
}

[[ $(grep -Fc "FROM $BASE_IMAGE" "$PROJECT_ROOT/Dockerfile") -eq 2 ]] || \
  fail "las dos etapas deben usar el digest del manifiesto"

if grep -REn '(^|[[:space:]@:/])latest([[:space:]@:/]|$)' \
  "$PROJECT_ROOT/Dockerfile" "$PROJECT_ROOT/container"; then
  fail "se encontro una dependencia latest"
fi

for variable in \
  DEBIAN_SNAPSHOT SOURCE_DATE_EPOCH GO_VERSION GO_SHA256_AMD64 GO_SHA256_ARM64 \
  SUBFINDER_VERSION DNSX_VERSION HTTPX_VERSION NAABU_VERSION KATANA_VERSION \
  NUCLEI_VERSION FFUF_VERSION GOBUSTER_VERSION GAU_VERSION \
  WAYBACKURLS_COMMIT HAKRAWLER_COMMIT GOWITNESS_COMMIT \
  PUREDNS_COMMIT MASSDNS_COMMIT NUCLEI_TEMPLATES_COMMIT; do
  value=${!variable}
  grep -Fq "ARG $variable=$value" "$PROJECT_ROOT/Dockerfile" || \
    fail "$variable no coincide entre Dockerfile y versions.env"
done

grep -Fq "ARG REKON_VERSION=$REKON_VERSION" "$PROJECT_ROOT/Dockerfile" || \
  fail "REKON_VERSION no coincide entre Dockerfile y versions.env"

[[ $GO_SHA256_AMD64 =~ ^[0-9a-f]{64}$ ]] || fail "hash Go amd64 no valido"
[[ $GO_SHA256_ARM64 =~ ^[0-9a-f]{64}$ ]] || fail "hash Go arm64 no valido"

for commit in \
  "$WAYBACKURLS_COMMIT" "$HAKRAWLER_COMMIT" \
  "$GOWITNESS_COMMIT" "$PUREDNS_COMMIT" "$MASSDNS_COMMIT" \
  "$NUCLEI_TEMPLATES_COMMIT"; do
  [[ $commit =~ ^[0-9a-f]{40}$ ]] || fail "commit no fijado a 40 caracteres: $commit"
done

grep -Fq "readonly REKON_VERSION=\"$REKON_VERSION\"" "$PROJECT_ROOT/rekon.sh" || \
  fail "version del script desalineada"
grep -Fq "image: \"\${REKON_IMAGE:-rekon:$REKON_VERSION}\"" "$PROJECT_ROOT/compose.yaml" || \
  fail "version de Compose desalineada"

[[ -s $PROJECT_ROOT/profiles/api-paths.txt ]] || fail "falta lista API"
[[ -s $PROJECT_ROOT/profiles/cloud-paths.txt ]] || fail "falta lista cloud"

grep -Fq 'GH_TOKEN: ${{ github.token }}' "$PROJECT_ROOT/.github/workflows/ci.yml" || \
  fail "el token automatico debe conservar la escritura de estados"
grep -Fq 'RELEASE_TOKEN: ${{ secrets.REKON_RELEASE_TOKEN }}' "$PROJECT_ROOT/.github/workflows/ci.yml" || \
  fail "falta el token dedicado de releases"
grep -Fq 'GH_TOKEN=$RELEASE_TOKEN gh "$@"' "$PROJECT_ROOT/.github/scripts/bootstrap-releases.sh" || \
  fail "las operaciones de release no usan el token dedicado"

if command -v docker >/dev/null 2>&1; then
  docker build --check "$PROJECT_ROOT"
fi

printf 'Container static test: OK\n'
