# Changelog

Todos los cambios relevantes de REKON se documentan aquí. El proyecto sigue
versionado semántico.

## [1.2.0] - 2026-08-19

### Añadido

- Imagen reproducible multi-stage para `linux/amd64` y `linux/arm64`, con base
  por digest, Debian Snapshot, Go verificado, herramientas fijadas y plantillas
  Nuclei congeladas.
- Flujo Docker/Podman, Compose, usuario sin privilegios y capacidades raw
  explícitas.
- Perfiles `ad`, `api`, `cloud` y `ot`, con evidencias propias en `11-profile/`.
- Listas integradas conservadoras para rutas API y cloud.
- Pruebas offline de los cuatro perfiles y validación estática del contenedor.
- Workflow idempotente para publicar releases y tags semánticos.
- Matriz explícita de verificación, cobertura y límites conocidos.

### Cambiado

- La versión de REKON pasa a 1.2.0.
- El informe registra descripción y política efectiva del perfil.
- La imagen desactiva instalaciones en tiempo de ejecución y actualizaciones de
  plantillas Nuclei.

### Corregido

- Compatibilidad completa con ShellCheck en el orquestador y sus pruebas.
- Verificación de capacidades de Nmap en el contenedor sin depender del `PATH`
  de una shell de login no privilegiada.
- Smoke tests del inventario runtime y dry-runs de todos los perfiles dentro de
  la imagen construida.

### Seguridad

- OT omite Naabu, Masscan, NSE, detección de SO, ICMP/traceroute, AXFR, consultas de protocolo, HTTP/TLS,
  crawling, fuzzing, Nuclei y capturas; aplica límites duros.
- AD reemplaza el conjunto NSE genérico por cuatro scripts SMB explícitos y
  consultas anónimas.
- Cloud evita metadata link-local y credenciales; API evita métodos de escritura
  e introspección GraphQL.

## [1.1.0] - 2026-08-19

- Instalación consentida, selección automática de diccionarios, TCP/UDP,
  enumeración web/DNS/servicios, trazabilidad, reanudación e informes.
