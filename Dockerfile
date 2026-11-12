# syntax=docker/dockerfile:1

# ============================================================================
# trex-sc v6 image  --  Seurat v6 (with native scSLIDE) single-cell stack
#   * RStudio Server + command-line R
#   * Everything updated to current; Seurat v6 installed from GitHub
#     (not yet on CRAN) and ships scSLIDE natively.
#   * Seurat ecosystem is its own early layer so it caches and you can start
#     working before the long tail finishes.
#
# Build: pushed to the seurat-v6 branch -> GitHub Actions -> ghcr.io/bixbeta/trex-sc:v6
# ============================================================================
FROM rocker/rstudio:4.5.1

LABEL org.opencontainers.image.title="trex-sc-v6" \
      org.opencontainers.image.description="Seurat v6 + scSLIDE single-cell image (RStudio + CLI)"

# Current CRAN snapshot; Bioconductor defaults to the release matching R 4.5.
ENV PPM_DATE="2026-11-01"
ARG AIR_VERSION=0.9.0
ARG QUARTO_VERSION=1.5.57

# Distro-aware PPM binary repo (works whether the base is jammy or noble).
RUN . /etc/os-release && \
    echo "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/${VERSION_CODENAME}/${PPM_DATE}'))" \
      >> "${R_HOME}/etc/Rprofile.site" && \
    echo "base distro: ${VERSION_CODENAME}"

# System libraries (names valid on both jammy and noble).
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates patch pkg-config cmake \
      libhdf5-dev libglpk-dev libgmp-dev libgsl-dev libfftw3-dev libgeos-dev \
      libxml2-dev libcurl4-openssl-dev libssl-dev libcairo2-dev \
      libharfbuzz-dev libfribidi-dev libfreetype6-dev \
      libpng-dev libjpeg-dev libtiff-dev libmagick++-dev \
      libbz2-dev liblzma-dev zlib1g-dev libgit2-dev git \
    && rm -rf /var/lib/apt/lists/*

# Quarto CLI
RUN curl -fsSL -o /tmp/quarto.deb \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && dpkg -i /tmp/quarto.deb && rm -f /tmp/quarto.deb && quarto --version

# Air (R formatter) binary
RUN set -eux; export AIR_INSTALL_DIR=/usr/local/bin; \
    curl -LsSf "https://github.com/posit-dev/air/releases/download/${AIR_VERSION}/air-installer.sh" -o /tmp/air.sh; \
    sh /tmp/air.sh; \
    if [ ! -x /usr/local/bin/air ]; then cp "$(find / -type f -name air -path '*bin*' 2>/dev/null | head -n1)" /usr/local/bin/air; fi; \
    chmod 0755 /usr/local/bin/air; rm -f /tmp/air.sh; air --version

RUN R -q -e "install.packages('pak')"

# --- Layer 1: Seurat v6 ecosystem + scSLIDE deps (the fast-start layer) ------
COPY install_seurat.R /tmp/install_seurat.R
RUN R -q -f /tmp/install_seurat.R && rm -f /tmp/install_seurat.R

# --- Layer 2: everything else (CRAN/Bioc) -----------------------------------
COPY install_rest.R /tmp/install_rest.R
RUN R -q -f /tmp/install_rest.R && rm -f /tmp/install_rest.R

# --- Layer 3: GitHub extras (best-effort) -----------------------------------
COPY install_github.R /tmp/install_github.R
RUN R -q -f /tmp/install_github.R && rm -f /tmp/install_github.R

# --- Layer 4: destiny (diffusion maps for scSLIDE; needs archived smoother) --
COPY install_destiny.R /tmp/install_destiny.R
RUN R -q -f /tmp/install_destiny.R && rm -f /tmp/install_destiny.R

EXPOSE 8787
