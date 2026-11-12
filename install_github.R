#!/usr/bin/env Rscript
# ============================================================================
# install_github.R  --  GitHub-only packages (best-effort)
#
# Runs after install_cran.R, so the Seurat stack these depend on is present.
# These are convenience extras, not the core single-cell stack, so a failure
# here does NOT fail the image build.
#
# Install order matters: Azimuth depends on SeuratData + SeuratDisk (both
# GitHub-only), so all GitHub packages are installed in ONE pak() call first,
# which lets pak resolve those cross-dependencies from their GitHub sources.
# If that batch solve fails, fall back to installing each package on its own
# so a single bad package doesn't drop the rest. Either way, exit 0.
# ============================================================================

options(
  repos = c(CRAN = Sys.getenv("PPM_SNAPSHOT")),
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

github <- c(
  "immunogenomics/presto",
  "satijalab/seurat-data",
  "mojaveazure/seurat-disk",
  "satijalab/seurat-wrappers",
  # Azimuth needs SeuratData + SeuratDisk resolved from GitHub, so it must be
  # in the same solve as them (above).
  "satijalab/azimuth",
  # BPCells moved its R package into the repo's r/ subdirectory.
  "bnprks/BPCells/r",
  "10XGenomics/loupeR"
)

message(">>> Installing GitHub packages together (resolves cross-deps) ...")
batch_ok <- tryCatch(
  {
    pak::pak(github, ask = FALSE, upgrade = FALSE)
    TRUE
  },
  error = function(e) {
    message(sprintf("!! batch install failed: %s", conditionMessage(e)))
    FALSE
  }
)

if (batch_ok) {
  message(">>> All GitHub packages installed.")
} else {
  message(">>> Falling back to per-package install ...")
  failed <- character(0)
  for (g in github) {
    message(sprintf(">>> Installing %s ...", g))
    ok <- tryCatch(
      {
        pak::pak(g, ask = FALSE, upgrade = FALSE)
        TRUE
      },
      error = function(e) {
        message(sprintf("!! FAILED %s: %s", g, conditionMessage(e)))
        FALSE
      }
    )
    if (!isTRUE(ok)) failed <- c(failed, g)
  }
  if (length(failed)) {
    message(paste0("GITHUB_FAILURES: ", paste(failed, collapse = " ")))
  }
}
# Exit 0 regardless: the image ships with whatever extras succeeded.
