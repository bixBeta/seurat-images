# syntax=docker/dockerfile:1

# ============================================================================
# TREx single-cell analysis image
#   * RStudio Server (web IDE)  +  command-line R (multi-day batch jobs)
#   * R 4.4.0 / Bioconductor 3.19, CRAN frozen to a dated PPM snapshot
#   * Seurat ecosystem pinned to the source-environment versions
#   * Air (Rust R formatter) on PATH for both the IDE and the CLI
#
# Build:  docker build -t trex-sc:1.0 .
#         (Dockerfile and install_packages.R must sit in the same directory)
# ============================================================================
FROM rocker/rstudio:4.4.0

LABEL org.opencontainers.image.title="trex-sc" \
      org.opencontainers.image.description="Reproducible Seurat v5 single-cell image (RStudio + CLI)" \
      org.opencontainers.image.authors="bixBeta"

# --- Reproducibility anchors ------------------------------------------------
# CRAN frozen to this date; __linux__/jammy serves precompiled binaries for
# Ubuntu 22.04 (the base OS of rocker/rstudio:4.4.0) -> fast, deterministic.
ENV PPM_SNAPSHOT="https://packagemanager.posit.co/cran/__linux__/jammy/2024-11-01"
# Pin Bioconductor to the release that matches R 4.4 (BiocManager reads this).
# 3.20 (Oct 2024) is in sync with the 2024-11 CRAN freeze and carries qs2.
ENV R_BIOC_VERSION="3.20"
ARG AIR_VERSION=0.9.0
ARG QUARTO_VERSION=1.5.57

# Point CRAN at the frozen snapshot for every R process (IDE + CLI + build).
RUN echo "options(repos = c(CRAN = '${PPM_SNAPSHOT}'))" \
      >> "${R_HOME}/etc/Rprofile.site"

# --- System libraries -------------------------------------------------------
# Covers hdf5r (hdf5), Signac/genomics (htslib deps: lzma/bz2/zlib, xml),
# igraph (glpk/gmp), text & graphics (harfbuzz/fribidi/freetype/cairo),
# magick, RcppGSL (gsl), fftw, and geos.
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates \
      patch pkg-config cmake \
      libhdf5-dev \
      libglpk-dev libgmp-dev \
      libgsl-dev \
      libfftw3-dev \
      libgeos-dev \
      libxml2-dev \
      libcurl4-openssl-dev libssl-dev \
      libcairo2-dev \
      libharfbuzz-dev libfribidi-dev libfreetype6-dev \
      libpng-dev libjpeg-dev libtiff5-dev \
      libmagick++-dev \
      libbz2-dev liblzma-dev zlib1g-dev \
      libgit2-dev git \
    && rm -rf /var/lib/apt/lists/*

# --- Quarto CLI (for .qmd reporting) ---------------------------------------
# rocker/rstudio bundles pandoc but not the Quarto CLI.
RUN curl -fsSL -o /tmp/quarto.deb \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && dpkg -i /tmp/quarto.deb \
    && rm -f /tmp/quarto.deb \
    && quarto --version

# --- Air: Rust-based R formatter (standalone binary, NOT an R package) ------
# Installed to /usr/local/bin so RStudio users and CLI jobs share one binary.
RUN set -eux; \
    export AIR_INSTALL_DIR=/usr/local/bin; \
    curl -LsSf "https://github.com/posit-dev/air/releases/download/${AIR_VERSION}/air-installer.sh" -o /tmp/air-installer.sh; \
    sh /tmp/air-installer.sh; \
    if [ ! -x /usr/local/bin/air ]; then \
      cp "$(find / -type f -name air -path '*bin*' 2>/dev/null | head -n1)" /usr/local/bin/air; \
    fi; \
    chmod 0755 /usr/local/bin/air; \
    rm -f /tmp/air-installer.sh; \
    air --version

# --- R packages -------------------------------------------------------------
# pak resolves the entire dependency graph in one solve, honouring the pins.
RUN R -q -e "install.packages('pak', repos = Sys.getenv('PPM_SNAPSHOT'))"
COPY install_packages.R /tmp/install_packages.R
RUN R -q -f /tmp/install_packages.R && rm -f /tmp/install_packages.R

EXPOSE 8787
