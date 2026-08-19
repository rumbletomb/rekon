#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

for required in GH_TOKEN GITHUB_REPOSITORY GITHUB_SHA RUNNER_TEMP; do
  if [[ -z ${!required:-} ]]; then
    printf 'Falta la variable requerida: %s\n' "$required" >&2
    exit 2
  fi
done

readonly GITHUB_SERVER_URL=${GITHUB_SERVER_URL:-https://github.com}
PHASE=initialization

post_status() {
  local state=$1 description=$2
  gh api --method POST \
    "repos/$GITHUB_REPOSITORY/statuses/$GITHUB_SHA" \
    -f state="$state" \
    -f context='rekon/releases' \
    -f description="$description" \
    -f target_url="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/tag/v1.2.0" \
    >/dev/null
}

on_error() {
  local exit_code=$1 line=$2
  trap - ERR
  set +e
  post_status failure "release failed in $PHASE (line $line)" >/dev/null 2>&1
  exit "$exit_code"
}
trap 'on_error "$?" "$LINENO"' ERR

post_status pending 'publishing v1.1.0 and v1.2.0'

git fetch --force --tags

notes_110="$RUNNER_TEMP/v1.1.0.md"
notes_120="$RUNNER_TEMP/v1.2.0.md"

cat >"$notes_110" <<'EOF_110'
REKON 1.1.0 establece el orquestador base de reconocimiento y enumeración para laboratorios autorizados.

Incluye instalación consentida, selección automática de diccionarios, reconocimiento TCP/UDP, enumeración web, DNS y de servicios, trazabilidad, reanudación e informes.

No incluye explotación, fuerza bruta de credenciales, denegación de servicio ni acciones destructivas.
EOF_110

cat >"$notes_120" <<'EOF_120'
REKON 1.2.0 añade un contenedor reproducible y perfiles especializados para Active Directory, API, cloud y OT/ICS.

Novedades principales:

- imagen multi-stage con base fijada por digest, Debian Snapshot, Go verificado y herramientas versionadas;
- ejecución Docker/Podman y Compose como usuario no privilegiado;
- perfiles ad, api, cloud y ot con políticas y evidencias separadas;
- límites especialmente conservadores para entornos OT;
- pruebas ShellCheck, smoke tests offline, construcción integral de la imagen, inventario runtime, dry-runs de todos los perfiles y comprobación raw de Nmap.

La validación reduce riesgos conocidos, pero no constituye una garantía absoluta para todas las redes, arquitecturas, servicios o versiones externas. Consulta docs/VERIFICATION.md.
EOF_120

ensure_release() {
  local tag=$1 target=$2 title=$3 notes=$4 mark_latest=$5 actual
  local tag_exists=false
  PHASE="checking $tag"
  if gh release view "$tag" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
    printf 'El release %s ya existe; no se modifica.\n' "$tag"
    return 0
  fi

  if git show-ref --verify --quiet "refs/tags/$tag"; then
    tag_exists=true
    actual=$(git rev-list -n 1 "$tag")
    if [[ $actual != "$target" ]]; then
      printf 'El tag %s apunta a %s, no a %s\n' "$tag" "$actual" "$target" >&2
      return 1
    fi
  fi

  PHASE="creating release $tag"
  local -a args=(
    release create "$tag"
    --repo "$GITHUB_REPOSITORY"
    --title "$title"
    --notes-file "$notes"
  )
  if [[ $tag_exists == true ]]; then
    args+=(--verify-tag)
  else
    args+=(--target "$target")
  fi
  if [[ $mark_latest == true ]]; then
    args+=(--latest)
  else
    args+=(--latest=false)
  fi
  gh "${args[@]}"
  gh release view "$tag" --repo "$GITHUB_REPOSITORY" >/dev/null
}

ensure_release v1.1.0 aacf15d797c91434f5ef7ea1c32a21469a73a870 \
  'REKON 1.1.0' "$notes_110" false
ensure_release v1.2.0 "$GITHUB_SHA" 'REKON 1.2.0' "$notes_120" true

PHASE=verification
gh release view v1.1.0 --repo "$GITHUB_REPOSITORY" >/dev/null
gh release view v1.2.0 --repo "$GITHUB_REPOSITORY" >/dev/null
post_status success 'v1.1.0 and v1.2.0 published'
trap - ERR
