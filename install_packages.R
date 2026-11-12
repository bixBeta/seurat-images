#!/usr/bin/env Rscript
# ============================================================================
# install_packages.R  --  package layer for the TREx single-cell image
#
# Strategy
#   * CRAN is frozen to a dated Posit Package Manager snapshot (Dockerfile:
#     PPM_SNAPSHOT) so every "floating" package resolves to one fixed set.
#   * Bioconductor is fixed to the release matching R 4.4 (3.19).
#   * The Seurat ecosystem is pinned to the source-environment versions so
#     SCTransform / clustering output stays comparable to prior analyses.
#   * pak solves the full graph in one pass, respecting the @version pins;
#     transitive dependencies resolve to their snapshot-stable versions.
#
# To add a package later: append its name to `pkgs` (CRAN or Bioc - pak
# auto-detects) or `github`, then rebuild. Dependencies are pulled
# automatically, so only direct-use packages need listing here.
# ============================================================================

options(
  repos = c(CRAN = Sys.getenv("PPM_SNAPSHOT")),
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

# ---- 1. Pinned Seurat ecosystem (exact versions, from source env) ----------
# All three are CRAN packages; pak pulls the exact version (from the archive
# if the snapshot's current version is newer).
pinned <- c(
  "Seurat@5.0.0",
  "sctransform@0.4.1",
  "Signac@1.12.0"
)
# NOTE: SeuratObject is intentionally NOT pinned to the exact 5.0.0 patch.
# Seurat 5.0.0 only requires SeuratObject >= 5.0.0, and forcing exactly 5.0.0
# made the dependency graph unsolvable (surrounding packages expect the 5.0.x
# bugfix line). It floats to 5.0.x; its patch level does not affect
# SCTransform / clustering output, and 5.0.2 pairs cleanly with Matrix 1.7.

# ---- 2. Floating packages (snapshot-stable) --------------------------------
# Mixed CRAN + Bioconductor; pak detects Bioc packages automatically.
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

# ---- 3. GitHub-only packages -----------------------------------------------
github <- c(
  "immunogenomics/presto",
  "satijalab/azimuth",
  "satijalab/seurat-wrappers",
  "mojaveazure/seurat-disk",
  "satijalab/seurat-data",
  "bnprks/BPCells",
  "10XGenomics/loupeR"
)

# ---- install ---------------------------------------------------------------
message(">>> Installing pinned Seurat ecosystem + CRAN/Bioc packages ...")
pak::pak(c(pinned, pkgs), ask = FALSE, upgrade = FALSE)

message(">>> Installing GitHub packages ...")
pak::pak(github, ask = FALSE, upgrade = FALSE)

# ---- verify the pins actually took -----------------------------------------
message(">>> Verifying pinned versions ...")
want <- c(Seurat = "5.0.0", sctransform = "0.4.1", Signac = "1.12.0")
for (p in names(want)) {
  got <- as.character(utils::packageVersion(p))
  flag <- if (identical(got, want[[p]])) "ok" else "MISMATCH"
  message(sprintf("    %-14s want %-8s got %-8s [%s]", p, want[[p]], got, flag))
}
message(sprintf("    %-14s (floated) got %s", "SeuratObject",
                as.character(utils::packageVersion("SeuratObject"))))

message(">>> Package layer complete.")
