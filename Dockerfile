# syntax=docker/dockerfile:1.7

# Debian is pinned by immutable multi-platform digest. Keep this value aligned
# with container/versions.env when intentionally refreshing the image.
FROM debian:bookworm-20260803-slim@sha256:abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241 AS tools

ARG DEBIAN_SNAPSHOT=20260803T000000Z
ARG GO_VERSION=1.26.6
ARG GO_SHA256_AMD64=708effb774be8237570d0add163225abbdfaf4fca28b2611df167beba4feef89
ARG GO_SHA256_ARM64=d0507e9e9d7fe012aae570108cbd76c15de879e17130ab8cb90d4d7445cb1f2e
ARG TARGETARCH
ARG SOURCE_DATE_EPOCH=1785715200

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN printf '%s\n' \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bookworm main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} bookworm-security main" \
      > /etc/apt/sources.list \
    && rm -f /etc/apt/sources.list.d/debian.sources \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git libpcap-dev \
    && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
      amd64) go_sha="${GO_SHA256_AMD64}" ;; \
      arm64) go_sha="${GO_SHA256_ARM64}" ;; \
      *) echo "Arquitectura no soportada: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl -fsSLo /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && printf '%s  %s\n' "${go_sha}" /tmp/go.tgz | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm -f /tmp/go.tgz

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}" \
    GOBIN=/go/bin \
    CGO_ENABLED=0 \
    GOTOOLCHAIN=local \
    GOFLAGS="-trimpath -buildvcs=false"

ARG SUBFINDER_VERSION=v2.15.0
ARG DNSX_VERSION=v1.3.0
ARG HTTPX_VERSION=v1.10.0
ARG NAABU_VERSION=v2.6.0
ARG KATANA_VERSION=v1.7.0
ARG NUCLEI_VERSION=v3.11.1
ARG FFUF_VERSION=v2.2.1
ARG GOBUSTER_VERSION=v3.8.2
ARG GAU_VERSION=v2.2.4
ARG WAYBACKURLS_COMMIT=86aeb97852707e1a6fb3bcd33e61d5433a6476c5
ARG HAKRAWLER_COMMIT=61905593d82e8bac87ff7a7cca32b2adde42bb60
ARG GOWITNESS_COMMIT=df54b384f4161a4fa2407238cc73ff6773b559b1
ARG PUREDNS_COMMIT=e1478a433e00bf3081d4bbb1e02b037a673c97ac

RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked \
    --mount=type=cache,target=/root/.cache/go-build,sharing=locked \
    tools=( \
      "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@${SUBFINDER_VERSION}" \
      "github.com/projectdiscovery/dnsx/cmd/dnsx@${DNSX_VERSION}" \
      "github.com/projectdiscovery/httpx/cmd/httpx@${HTTPX_VERSION}" \
      "github.com/projectdiscovery/naabu/v2/cmd/naabu@${NAABU_VERSION}" \
      "github.com/projectdiscovery/katana/cmd/katana@${KATANA_VERSION}" \
      "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@${NUCLEI_VERSION}" \
      "github.com/ffuf/ffuf/v2@${FFUF_VERSION}" \
      "github.com/OJ/gobuster/v3@${GOBUSTER_VERSION}" \
      "github.com/lc/gau/v2/cmd/gau@${GAU_VERSION}" \
      "github.com/tomnomnom/waybackurls@${WAYBACKURLS_COMMIT}" \
      "github.com/hakluke/hakrawler@${HAKRAWLER_COMMIT}" \
      "github.com/sensepost/gowitness@${GOWITNESS_COMMIT}" \
      "github.com/d3mondev/puredns/v2@${PUREDNS_COMMIT}" \
    ) \
    && for tool in "${tools[@]}"; do \
         go install -ldflags='-s -w -buildid=' "$tool"; \
       done \
    && for binary in subfinder dnsx httpx naabu katana nuclei ffuf gobuster gau waybackurls hakrawler gowitness puredns; do \
         test -x "/go/bin/${binary}" || exit 1; \
       done

ARG MASSDNS_COMMIT=ca8114164361f6a296399d8160bb07d55bdc4843
RUN git init /src/massdns \
    && git -C /src/massdns remote add origin https://github.com/blechschmidt/massdns.git \
    && git -C /src/massdns fetch --depth 1 origin "${MASSDNS_COMMIT}" \
    && git -C /src/massdns checkout --detach FETCH_HEAD \
    && make -C /src/massdns \
    && install -m 0755 /src/massdns/bin/massdns /go/bin/massdns

ARG NUCLEI_TEMPLATES_COMMIT=83234ce456da3e90dda86dfbc5e605e64a846df3
RUN git init /opt/nuclei-templates \
    && git -C /opt/nuclei-templates remote add origin https://github.com/projectdiscovery/nuclei-templates.git \
    && git -C /opt/nuclei-templates fetch --depth 1 origin "${NUCLEI_TEMPLATES_COMMIT}" \
    && git -C /opt/nuclei-templates checkout --detach FETCH_HEAD \
    && rm -rf /opt/nuclei-templates/.git \
    && find /opt/nuclei-templates -exec touch -d "@${SOURCE_DATE_EPOCH}" {} +


FROM debian:bookworm-20260803-slim@sha256:abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241 AS runtime

ARG DEBIAN_SNAPSHOT=20260803T000000Z
ARG REKON_VERSION=1.2.0

LABEL org.opencontainers.image.title="REKON" \
      org.opencontainers.image.description="Reconocimiento y enumeración para laboratorios autorizados" \
      org.opencontainers.image.version="${REKON_VERSION}" \
      org.opencontainers.image.source="https://github.com/rumbletomb/rekon" \
      org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN printf '%s\n' \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bookworm main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} bookworm-security main" \
      > /etc/apt/sources.list \
    && rm -f /etc/apt/sources.list.d/debian.sources \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash ca-certificates chromium coreutils curl dnsutils findutils gawk grep \
      iputils-ping jq ldap-utils libcap2-bin nfs-common nmap openssh-client \
      openssl pandoc python3 rpcbind sed smbclient sslscan tini traceroute whois \
    && rm -rf /var/lib/apt/lists/*

COPY --from=tools /go/bin/ /usr/local/bin/
COPY --from=tools /opt/nuclei-templates/ /opt/nuclei-templates/
COPY rekon.sh requirements-tools.tsv LICENSE README.md CHANGELOG.md /opt/rekon/
COPY profiles/ /opt/rekon/profiles/
COPY docs/ /opt/rekon/docs/
COPY container/versions.env /opt/rekon/container/versions.env
COPY container/entrypoint.sh /usr/local/bin/rekon-entrypoint

RUN groupadd --gid 10001 rekon \
    && useradd --uid 10001 --gid 10001 --create-home --home-dir /home/rekon --shell /bin/bash rekon \
    && install -d -o 10001 -g 10001 /output /wordlists /work \
    && chmod 0755 /opt/rekon/rekon.sh /usr/local/bin/rekon-entrypoint \
    && setcap cap_net_raw,cap_net_admin+eip /usr/bin/nmap \
    && setcap cap_net_raw,cap_net_admin+eip /usr/local/bin/naabu \
    && chown -R 10001:10001 /opt/nuclei-templates

ENV REKON_CONTAINER=1 \
    REKON_BIN_DIR=/usr/local/bin \
    REKON_WORDLIST_DIR=/wordlists \
    REKON_OUTPUT_DIR=/output \
    REKON_NUCLEI_TEMPLATES=/opt/nuclei-templates \
    HOME=/tmp/rekon-home \
    PATH="/usr/local/bin:${PATH}"

USER 10001:10001
WORKDIR /work
VOLUME ["/wordlists", "/output"]
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/rekon-entrypoint"]
