#!/usr/bin/env Rscript
# ============================================================================
# install_seurat.R  --  Seurat v6 ecosystem + scSLIDE deps (fast-start layer)
#
# Seurat v6.0.0 is GitHub-only (not yet on CRAN) and ships scSLIDE natively
# (PrepareSampleObject, GenerateSampleObject, RunPLS, SketchDataByGroup, ...).
# The scSLIDE method needs glmGamPoi + destiny (Bioc) and pls + spls (CRAN).
# ============================================================================

options(
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

message(">>> Installing Seurat v6 core + scSLIDE deps ...")
pak::pak(c(
  "satijalab/seurat@v6.0.0",   # v6, with native scSLIDE; pulls SeuratObject >= 5.3.0
  "sctransform",
  "Signac",
  "glmGamPoi",                 # Bioc: SCT + scSLIDE DE
  "pls",                       # scSLIDE: PLS reductions (RunPLS)
  "spls",                      # scSLIDE: sparse PLS
  "harmony",
  "SingleCellExperiment",
  "SummarizedExperiment"
), ask = FALSE)

# destiny (diffusion maps, a secondary scSLIDE feature) pulls 'smoother' and a
# long chain of heavy deps that can fail to resolve. Keep it non-blocking so
# the image still ships Seurat v6 + the scSLIDE core workflow.
message(">>> Installing destiny (optional scSLIDE diffusion-map dep) ...")
destiny_ok <- tryCatch(
  {
    pak::pak("destiny", ask = FALSE)
    TRUE
  },
  error = function(e) {
    message(sprintf("!! destiny skipped: %s", conditionMessage(e)))
    FALSE
  }
)
if (!destiny_ok) message("DESTINY_SKIPPED")

sv <- as.character(utils::packageVersion("Seurat"))
message(sprintf(">>> Seurat %s  (want 6.x)  [%s]", sv,
                if (startsWith(sv, "6.")) "ok" else "CHECK"))
message(sprintf(">>> SeuratObject %s | sctransform %s | Signac %s",
                utils::packageVersion("SeuratObject"),
                utils::packageVersion("sctransform"),
                utils::packageVersion("Signac")))
message(">>> Seurat layer complete.")
