# Verificación y límites de REKON

REKON no se presenta como software infalible. El objetivo de esta matriz es
distinguir las propiedades comprobadas de aquellas que dependen del entorno,
la red o herramientas externas.

## Verificado automáticamente

El workflow de CI se ejecuta sobre un runner Linux `ubuntu-latest`:

- sintaxis de todos los scripts Bash con `bash -n`;
- análisis estático con ShellCheck;
- autotest de validación de objetivos, puertos y perfiles;
- smoke tests offline de `passive`, `balanced`, `deep`, `ad`, `api`, `cloud`
  y `ot`;
- límites de seguridad OT y ausencia de comandos activos prohibidos;
- coherencia entre versión, Dockerfile, Compose y manifiesto de dependencias;
- fijación por digest, versiones y commits de las dependencias del contenedor;
- construcción completa de la imagen `linux/amd64`;
- presencia de las herramientas y listas necesarias en la etapa runtime;
- versión y self-test ejecutados dentro del contenedor como usuario no root;
- dry-run de los siete perfiles dentro de la imagen;
- capacidades Linux de Nmap y descubrimiento real de loopback.

Las pruebas de dry-run usan dominios reservados y no emiten tráfico hacia
terceros.

## No demostrado por esta matriz

- funcionamiento exhaustivo frente a todas las combinaciones de servicios,
  firewalls, proxies, DNS, latencias y pérdidas de red;
- disponibilidad o estabilidad futura de fuentes OSINT y herramientas externas;
- ejecución real de cada módulo sobre Active Directory, API, proveedores cloud
  y dispositivos OT de todos los fabricantes;
- instalación nativa sobre cada versión de Debian, Ubuntu, Kali, Fedora, Arch u
  otros sistemas compatibles;
- construcción y ejecución completa de la imagen `linux/arm64`;
- ausencia absoluta de defectos, falsos positivos o falsos negativos.

Por ello, una ejecución satisfactoria de CI permite publicar una versión con un
nivel de confianza razonable y reproducible, pero no justificar una garantía de
funcionamiento del 100 %.

## Reproducción local

```bash
bash -n rekon.sh container/*.sh tests/*.sh
shellcheck -x rekon.sh container/*.sh tests/*.sh
bash rekon.sh --self-test
bash tests/container-static.sh
bash tests/smoke.sh
docker build --pull --tag rekon-ci:1.2.0 .
docker run --rm rekon-ci:1.2.0 --self-test
```

Los reconocimientos activos deben probarse exclusivamente en un laboratorio
propio o dentro de un alcance autorizado por escrito.
