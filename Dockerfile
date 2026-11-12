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
# Split into two layers so the heavy CRAN/Bioc install caches independently of
# the GitHub-package layer; iterating on GitHub pkgs then costs seconds.
RUN R -q -e "install.packages('pak', repos = Sys.getenv('PPM_SNAPSHOT'))"

# Layer 1: pinned Seurat engine + all CRAN/Bioc packages (the long pole).
COPY install_cran.R /tmp/install_cran.R
RUN R -q -f /tmp/install_cran.R && rm -f /tmp/install_cran.R

# Layer 2: GitHub-only packages (depend on the Seurat stack from layer 1).
COPY install_github.R /tmp/install_github.R
RUN R -q -f /tmp/install_github.R && rm -f /tmp/install_github.R

# Layer 3: TBB-enabled qs2 (multithreaded qs_save/qs_read).
# The PPM qs2 binary is built without TBB, so nthreads > 1 errors out. Install
# TBB and rebuild qs2 from source so it links against it. The final check fails
# the build if multithreading isn't actually working.
RUN apt-get update && apt-get install -y --no-install-recommends libtbb-dev \
    && rm -rf /var/lib/apt/lists/* \
    && R -q -e "install.packages('qs2', type='source', repos='https://packagemanager.posit.co/cran/2024-11-01')" \
    && R -q -e "f <- tempfile(fileext='.qs'); qs2::qs_save(1:10, f, nthreads = 2L); stopifnot(identical(qs2::qs_read(f, nthreads = 2L), 1:10)); cat('qs2 TBB multithreading OK\n')"

EXPOSE 8787
