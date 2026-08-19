# Perfiles de reconocimiento

Los perfiles son políticas completas: seleccionan puertos, tasa, concurrencia,
límites y módulos. Solo se elige uno por ejecución. Los perfiles generales
(`passive`, `balanced`, `deep`) se conservan y REKON 1.2.0 añade cuatro perfiles
tecnológicos.

| Perfil | Propósito | TCP / UDP inicial | Actividad específica |
|---|---|---|---|
| `passive` | Fuentes pasivas | ninguno / ninguno | Sin sondeo activo |
| `balanced` | Recon general | top 1000 / top 50 | Web, fuzzing y Nuclei acotados |
| `deep` | Recon exhaustivo | todos / top 200 | Listas grandes y motores complementarios |
| `ad` | Active Directory | puertos AD / UDP AD | SRV, RootDSE y SMB/RPC anónimo |
| `api` | APIs HTTP | puertos API / ninguno | OpenAPI/Swagger, crawling y parámetros GET |
| `cloud` | Superficie cloud pública | web / ninguno | CNAME, identidad federada y huellas de proveedor |
| `ot` | OT/ICS conservador | lista OT / lista OT | Puerto y versión ligera; sin consultas de protocolo |

La política efectiva se guarda siempre en
`00-meta/profile-policy.tsv`; los artefactos especializados quedan en
`11-profile/`.

## Active Directory (`ad`)

- Puertos de DNS, Kerberos, RPC, SMB, LDAP/LDAPS, Global Catalog, RDP y WinRM.
- Registros SRV `_ldap`, `_kerberos` y `_gc` para un FQDN.
- RootDSE anónimo en 389, 636, 3268 y 3269.
- Listado SMB y `rpcclient srvinfo` únicamente de forma anónima.
- NSE genérico desactivado; solo ejecuta explícitamente
  `smb2-capabilities`, `smb2-security-mode`, `smb2-time` y
  `smb-os-discovery` sobre 445.

No enumera usuarios, no prueba contraseñas, no hace Kerberoasting y no solicita
ni reutiliza credenciales.

## API (`api`)

- Prioriza puertos habituales de gateways y servicios de desarrollo.
- Usa la lista integrada [`profiles/api-paths.txt`](../profiles/api-paths.txt)
  para localizar OpenAPI, Swagger, Redoc, GraphQL, OIDC, salud y métricas.
- Amplía Katana/Hakrawler y el descubrimiento de parámetros GET.
- Mantiene FFUF, TLS, capturas y Nuclei no intrusivo.

Las rutas integradas se consultan solo mediante GET o HEAD. No hay introspección
GraphQL, mutaciones ni métodos HTTP de escritura.

## Cloud (`cloud`)

- Correlaciona DNS, CNAME, cabeceras, TLS y tecnologías públicas.
- Busca OIDC/JWKS y ficheros públicos mediante
  [`profiles/cloud-paths.txt`](../profiles/cloud-paths.txt).
- Extrae indicadores de AWS, Azure, GCP, Cloudflare y otros proveedores desde
  evidencias ya obtenidas.

No consulta endpoints link-local de metadata, no enumera cuentas, buckets o
tenants por diccionario y no usa credenciales cloud.

## OT/ICS (`ot`)

El perfil OT parte de la premisa de que algunos equipos pueden ser frágiles:

- 4 hilos, tasa 5/s y máximo 25 hosts por defecto.
- Nmap `-T2`, `--version-light` y cero reintentos.
- Naabu, Masscan, NSE, detección de SO, ICMP/traceroute, AXFR, consultas de servicio, HTTP, TLS, crawling,
  fuzzing, Nuclei y capturas desactivados.
- Solo correlaciona puertos abiertos con candidatos de protocolo; no envía
  peticiones Modbus, S7, DNP3, BACnet, EtherNet/IP u OPC UA.
- Topes duros: 10 hilos, 20/s y 100 hosts.
- `--tcp-ports` y `--udp-ports` solo admiten una lista/rango explícito o `none`;
  `top*` y `all` se rechazan.

La autorización del laboratorio sigue siendo obligatoria. Antes de usar OT,
valida además la ventana, el estado del proceso y las restricciones del
fabricante.

## Ejemplos

```bash
./rekon.sh -t dc.lab.example -w /usr/share/seclists -p ad \
  --sudo-scans --accept-authorized-use --non-interactive

./rekon.sh -t api.lab.example -w /usr/share/seclists -p api \
  --no-sudo-scans --accept-authorized-use --non-interactive

./rekon.sh -t 192.168.56.40 -w /usr/share/seclists -p ot \
  --tcp-ports 80,102,443,502,2404,4840,44818 \
  --udp-ports 161,47808 \
  --sudo-scans --accept-authorized-use --non-interactive
```

Usa `--dry-run` para revisar el plan y `--only`/`--skip` para acotar módulos sin
alterar la política base.
