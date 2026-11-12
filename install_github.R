#!/usr/bin/env Rscript
# ============================================================================
# install_github.R  --  GitHub-only extras (best-effort)
# repos is set in Rprofile.site; do not override it here.
# Installed as one solve so cross-deps (Azimuth -> SeuratData/SeuratDisk)
# resolve; per-package fallback keeps one failure from dropping the rest.
# NOTE: Azimuth may lag Seurat v6 — if so it is logged and skipped, not fatal.
# ============================================================================

options(
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

github <- c(
  "immunogenomics/presto",
  "satijalab/seurat-data",
  "mojaveazure/seurat-disk",
  "satijalab/seurat-wrappers",
  "satijalab/azimuth",
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
# Exit 0 regardless.
