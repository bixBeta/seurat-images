#!/usr/bin/env Rscript
# ============================================================================
# install_cran.R  --  CRAN + Bioconductor layer (the long pole)
#
# Kept separate from the GitHub layer so this heavy install caches on its own:
# iterating on GitHub-only packages then costs seconds, not a full re-install.
#
# Strategy
#   * CRAN frozen to a dated PPM snapshot (Dockerfile: PPM_SNAPSHOT).
#   * Bioconductor fixed to the release matching R 4.4 (3.20).
#   * sctransform (SCT engine) + Signac (ATAC) pinned to the source-env
#     versions; Seurat/SeuratObject float on the v5 line (see note below).
#   * pak solves the whole graph in one pass, honouring the pins.
# ============================================================================

options(
  repos = c(CRAN = Sys.getenv("PPM_SNAPSHOT")),
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

# ---- Pinned packages (SCT engine + ATAC) -----------------------------------
# sctransform governs SCTransform numerics; Signac is pinned for ATAC /
# multiome reproducibility.
#
# Seurat and SeuratObject are intentionally NOT pinned to 5.0.0. qs2 forces a
# late-2024 snapshot, and in that universe newer packages require Seurat >
# 5.0.0, so an exact 5.0.0 pin is unsolvable. They float on the 5.1.x line;
# SCT / clustering output is driven by sctransform (pinned) + glmGamPoi, not
# by Seurat's minor version, so results stay comparable.
pinned <- c(
  "sctransform@0.4.1",
  "Signac@1.12.0"
)

# ---- Floating CRAN + Bioconductor packages (snapshot-stable) ---------------
# pak auto-detects which are Bioconductor.
pkgs <- c(
  # -- core workflow / tooling --
  "tidyverse", "data.table", "here", "fs", "glue", "cli",
  "devtools", "remotes", "BiocManager", "reticulate",
  "qs2", "future", "future.apply", "progressr", "R.utils",

  # -- single-cell core --
  "glmGamPoi", "harmony", "SingleCellExperiment", "SummarizedExperiment",
  "scran", "scater", "scuttle", "bluster", "batchelor", "beachmat",
  "DropletUtils", "scDblFinder", "scds", "SoupX", "celda",
  "UCell", "VAM", "SingleR", "celldex", "M3Drop", "scMerge", "zinbwave",
  "TSCAN", "singleCellTK", "monocle",

  # -- bulk RNA-seq / DE / enrichment --
  "DESeq2", "edgeR", "limma", "MAST", "fgsea",
  "clusterProfiler", "DOSE", "enrichplot", "GSVA", "GSVAdata", "GSEABase",
  "msigdbr", "babelgene", "enrichR", "fishpond", "tximport", "sva",

  # -- annotation / references --
  "AnnotationHub", "AnnotationDbi", "org.Hs.eg.db", "GO.db", "GOSemSim",
  "KEGGREST", "biomaRt", "ensembldb", "EnsDb.Hsapiens.v86",
  "GenomicFeatures", "GenomicRanges", "rtracklayer", "Biostrings",
  "BSgenome", "BSgenome.Hsapiens.UCSC.hg38", "TENxPBMCData", "scRNAseq",

  # -- ATAC / motif (Signac multiome work) --
  "TFBSTools", "JASPAR2020", "CNEr", "seqLogo",

  # -- HDF5 / IO --
  "hdf5r", "rhdf5", "HDF5Array", "WriteXLS",

  # -- visualization --
  "patchwork", "cowplot", "ggrepel", "ggridges", "plotly", "DT",
  "pheatmap", "ComplexHeatmap", "circlize", "ggraph", "ggforce",
  "scatterpie", "ggtree", "viridis", "RColorBrewer", "Cairo", "ragg",
  "magick", "corrplot", "gplots", "colourpicker", "ggnewscale",
  "ggplotify", "echarts4r",

  # -- shiny stack (QC-CheckeR / DEG-Explorer) --
  "shiny", "shinydashboard", "shinyjs", "shinyBS", "shinycssloaders",
  "shinyalert", "bslib", "htmltools",

  # -- stats / dimensionality reduction --
  "xgboost", "mclust", "uwot", "Rtsne", "igraph", "leiden", "leidenbase",
  "RSpectra", "irlba", "rsvd", "kernlab", "RcppHNSW", "RcppAnnoy",

  # -- reporting --
  "rmarkdown", "knitr", "quarto", "bookdown", "rmdformats"
)

message(">>> Installing pinned Seurat engine + CRAN/Bioc packages ...")
pak::pak(c(pinned, pkgs), ask = FALSE, upgrade = FALSE)

# ---- verify the pins + Seurat major version --------------------------------
message(">>> Verifying versions ...")
want <- c(sctransform = "0.4.1", Signac = "1.12.0")
for (p in names(want)) {
  got <- as.character(utils::packageVersion(p))
  flag <- if (identical(got, want[[p]])) "ok" else "MISMATCH"
  message(sprintf("    %-14s want %-8s got %-8s [%s]", p, want[[p]], got, flag))
}
sv <- as.character(utils::packageVersion("Seurat"))
message(sprintf("    %-14s want 5.x.x   got %-8s [%s]", "Seurat",
                sv, if (startsWith(sv, "5.")) "ok" else "MISMATCH"))
message(sprintf("    %-14s (floated) got %s", "SeuratObject",
                as.character(utils::packageVersion("SeuratObject"))))

message(">>> CRAN/Bioc layer complete.")
