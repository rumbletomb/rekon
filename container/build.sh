#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=container/versions.env
source "$PROJECT_ROOT/container/versions.env"

ENGINE=${CONTAINER_ENGINE:-docker}
IMAGE=${REKON_IMAGE:-rekon:${REKON_VERSION}}
command -v "$ENGINE" >/dev/null 2>&1 || {
  printf 'No se encontro el motor de contenedores: %s\n' "$ENGINE" >&2
  exit 127
}

args=(
  build --pull
  --tag "$IMAGE"
  --build-arg "REKON_VERSION=$REKON_VERSION"
  --build-arg "DEBIAN_SNAPSHOT=$DEBIAN_SNAPSHOT"
  --build-arg "SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH"
  --build-arg "GO_VERSION=$GO_VERSION"
  --build-arg "GO_SHA256_AMD64=$GO_SHA256_AMD64"
  --build-arg "GO_SHA256_ARM64=$GO_SHA256_ARM64"
  --build-arg "SUBFINDER_VERSION=$SUBFINDER_VERSION"
  --build-arg "DNSX_VERSION=$DNSX_VERSION"
  --build-arg "HTTPX_VERSION=$HTTPX_VERSION"
  --build-arg "NAABU_VERSION=$NAABU_VERSION"
  --build-arg "KATANA_VERSION=$KATANA_VERSION"
  --build-arg "NUCLEI_VERSION=$NUCLEI_VERSION"
  --build-arg "FFUF_VERSION=$FFUF_VERSION"
  --build-arg "GOBUSTER_VERSION=$GOBUSTER_VERSION"
  --build-arg "GAU_VERSION=$GAU_VERSION"
  --build-arg "WAYBACKURLS_COMMIT=$WAYBACKURLS_COMMIT"
  --build-arg "HAKRAWLER_COMMIT=$HAKRAWLER_COMMIT"
  --build-arg "GOWITNESS_COMMIT=$GOWITNESS_COMMIT"
  --build-arg "PUREDNS_COMMIT=$PUREDNS_COMMIT"
  --build-arg "MASSDNS_COMMIT=$MASSDNS_COMMIT"
  --build-arg "NUCLEI_TEMPLATES_COMMIT=$NUCLEI_TEMPLATES_COMMIT"
  "$PROJECT_ROOT"
)

printf 'Construyendo %s con %s (base %s)\n' "$IMAGE" "$ENGINE" "$BASE_IMAGE"
exec "$ENGINE" "${args[@]}"
