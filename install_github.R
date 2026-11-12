#!/usr/bin/env Rscript
# ============================================================================
# install_github.R  --  GitHub-only packages (best-effort)
#
# Runs after install_cran.R, so the Seurat stack these depend on is present.
# These are convenience extras, not the core single-cell stack, so a failure
# in one does NOT fail the image build: each is attempted independently, any
# failures are logged loudly (GITHUB_FAILURES:) and the script still exits 0.
# Kept in its own Docker layer so fixes here are cheap to iterate.
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

ok <- character(0)
failed <- character(0)
for (g in github) {
  message(sprintf(">>> Installing %s ...", g))
  res <- tryCatch(
    {
      pak::pak(g, ask = FALSE, upgrade = FALSE)
      TRUE
    },
    error = function(e) {
      message(sprintf("!! FAILED %s: %s", g, conditionMessage(e)))
      FALSE
    }
  )
  if (isTRUE(res)) ok <- c(ok, g) else failed <- c(failed, g)
}

message(sprintf(">>> GitHub layer: %d ok, %d failed", length(ok), length(failed)))
if (length(failed)) {
  # Grep-friendly marker so CI / tooling can spot incomplete extras.
  message(paste0("GITHUB_FAILURES: ", paste(failed, collapse = " ")))
}
# Exit 0 regardless: the image ships with whatever extras succeeded.
