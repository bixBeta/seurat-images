#!/usr/bin/env Rscript
# ============================================================================
# install_github.R  --  GitHub-only packages
#
# Runs after install_cran.R, so the Seurat stack these depend on is already
# present. Kept in its own Docker layer so fixes here are cheap to iterate.
# ============================================================================

options(
  repos = c(CRAN = Sys.getenv("PPM_SNAPSHOT")),
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

github <- c(
  "immunogenomics/presto",
  "satijalab/azimuth",
  "satijalab/seurat-wrappers",
  "mojaveazure/seurat-disk",
  "satijalab/seurat-data",
  # BPCells moved its R package into the repo's r/ subdirectory; the repo root
  # is now a stub that errors with "installation location has moved".
  "bnprks/BPCells/r",
  "10XGenomics/loupeR"
)

message(">>> Installing GitHub packages ...")
pak::pak(github, ask = FALSE, upgrade = FALSE)

message(">>> GitHub layer complete.")
