# Contenedor reproducible

La imagen de REKON 1.2.0 está pensada para laboratorios donde el host no tiene
un gestor compatible o no debe modificarse. Admite `linux/amd64` y
`linux/arm64`.

## Garantías de construcción

- Debian se fija por etiqueta fechada y digest OCI inmutable.
- APT usa una instantánea fechada de Debian Snapshot.
- Go se descarga en una versión exacta y se valida con SHA-256 por arquitectura.
- Las herramientas Go usan versiones o commits concretos; no hay `latest`.
- MassDNS y las plantillas de Nuclei se obtienen desde commits completos.
- [`container/versions.env`](../container/versions.env) centraliza el manifiesto
  auditable que utiliza el constructor.

Esto fija los insumos de la imagen. No promete que dos motores, sistemas de
ficheros o versiones de BuildKit produzcan un ID de imagen bit a bit idéntico.

## Construcción

Requiere Docker con BuildKit o Podman compatible:

```bash
./container/build.sh

# Podman
CONTAINER_ENGINE=podman ./container/build.sh

# Nombre de imagen personalizado
REKON_IMAGE=registry.local/lab/rekon:1.2.0 ./container/build.sh
```

El script transmite al `Dockerfile` todas las versiones del manifiesto. También
puedes usar `docker compose build`, que emplea los valores fijados por defecto en
el propio `Dockerfile`.

## Ejecución con Docker

```bash
mkdir -p ./rekon-output

docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  --cap-add NET_RAW \
  --cap-add NET_ADMIN \
  -v /usr/share/seclists:/wordlists:ro \
  -v "$PWD/rekon-output:/output" \
  rekon:1.2.0 \
  --target dc.lab.example \
  --profile ad \
  --sudo-scans \
  --accept-authorized-use \
  --non-interactive
```

REKON se ejecuta como UID/GID `10001`, no como root, salvo que `--user` lo
iguale al operador para poder escribir en el bind mount. Las capacidades de
fichero se limitan a Nmap y Naabu, y el runtime solo recibe `NET_RAW` y
`NET_ADMIN`; no uses `--privileged`. Si no quieres sockets raw, omite
`--cap-add`, añade `--security-opt no-new-privileges` y usa `--no-sudo-scans`;
Nmap realizará TCP connect y REKON omitirá UDP.

Para objetivos que están en la misma máquina, Linux puede requerir
`--network host`. No lo actives salvo que el laboratorio lo necesite.

## Docker Compose

```bash
REKON_WORDLISTS=/usr/share/seclists \
REKON_OUTPUT="$PWD/rekon-output" \
REKON_UID="$(id -u)" REKON_GID="$(id -g)" \
docker compose run --rm rekon \
  -t api.lab.example -p api \
  --sudo-scans --accept-authorized-use --non-interactive
```

La red predeterminada es `bridge`. Para usar la red del host en Linux:

```bash
REKON_NETWORK_MODE=host docker compose run --rm rekon \
  -t 192.168.56.20 -p ot \
  --sudo-scans --accept-authorized-use --non-interactive
```

## Contenido de la imagen

La pila fijada incluye Nmap, MassDNS, Subfinder, Dnsx, httpx, Naabu, Katana,
Nuclei, FFUF, Gobuster, gau, waybackurls, Hakrawler, Gowitness,
Puredns, Chromium, Curl, Dig, Whois, smbclient, rpcclient, ldapsearch, sslscan,
OpenSSL y Pandoc. Las plantillas oficiales de Nuclei están fijadas y REKON
desactiva su actualización automática durante el escaneo.

Algunas herramientas opcionales del instalador nativo —por ejemplo Assetfinder,
Amass, Feroxbuster, Arjun, WhatWeb, WAFW00F y testssl.sh— no forman parte de la imagen.
REKON usa sus alternativas incluidas y deja constancia en el inventario.

## Operación y actualización

- `/wordlists` es de solo lectura y debe contener los diccionarios del operador.
- `/output` contiene el expediente persistente.
- `--install-deps` se ignora dentro de la imagen inmutable; para cambiar
  dependencias se reconstruye la imagen.
- `rekon shell` abre Bash para diagnóstico sin cambiar el punto de entrada.

Para actualizar la cadena de suministro, modifica en el mismo cambio
`Dockerfile`, `container/versions.env`, documentación y pruebas; valida los
nuevos hashes antes de publicar.
