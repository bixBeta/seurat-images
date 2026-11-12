#!/usr/bin/env Rscript
# ============================================================================
# install_rest.R  --  everything else (CRAN + Bioconductor), current versions
# Runs after the Seurat layer. repos is set in Rprofile.site (distro-aware PPM),
# so this script does not override it. pak auto-detects Bioconductor packages.
# ============================================================================

options(
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

pkgs <- c(
  # core workflow / tooling
  "tidyverse", "data.table", "here", "fs", "glue", "cli",
  "devtools", "remotes", "BiocManager", "reticulate",
  "qs2", "future", "future.apply", "progressr", "R.utils",

  # single-cell (non-Seurat-core; Seurat stack is in install_seurat.R)
  "scran", "scater", "scuttle", "bluster", "batchelor", "beachmat",
  "DropletUtils", "scDblFinder", "scds", "SoupX", "celda",
  "UCell", "VAM", "SingleR", "celldex", "M3Drop", "scMerge", "zinbwave",
  "TSCAN", "singleCellTK", "monocle",

  # bulk RNA-seq / DE / enrichment
  "DESeq2", "edgeR", "limma", "MAST", "fgsea",
  "clusterProfiler", "DOSE", "enrichplot", "GSVA", "GSVAdata", "GSEABase",
  "msigdbr", "babelgene", "enrichR", "fishpond", "tximport", "sva",

  # annotation / references
  "AnnotationHub", "AnnotationDbi", "org.Hs.eg.db", "GO.db", "GOSemSim",
  "KEGGREST", "biomaRt", "ensembldb", "EnsDb.Hsapiens.v86",
  "GenomicFeatures", "GenomicRanges", "rtracklayer", "Biostrings",
  "BSgenome", "BSgenome.Hsapiens.UCSC.hg38", "TENxPBMCData", "scRNAseq",

  # ATAC / motif
  "TFBSTools", "JASPAR2020", "CNEr", "seqLogo",

  # HDF5 / IO
  "hdf5r", "rhdf5", "HDF5Array", "WriteXLS",

  # visualization
  "patchwork", "cowplot", "ggrepel", "ggridges", "plotly", "DT",
  "pheatmap", "ComplexHeatmap", "circlize", "ggraph", "ggforce",
  "scatterpie", "ggtree", "viridis", "RColorBrewer", "Cairo", "ragg",
  "magick", "corrplot", "gplots", "colourpicker", "ggnewscale",
  "ggplotify", "echarts4r",

  # shiny
  "shiny", "shinydashboard", "shinyjs", "shinyBS", "shinycssloaders",
  "shinyalert", "bslib", "htmltools",

  # stats / dimensionality reduction
  "xgboost", "mclust", "uwot", "Rtsne", "igraph", "leiden", "leidenbase",
  "RSpectra", "irlba", "rsvd", "kernlab", "RcppHNSW", "RcppAnnoy",

  # reporting
  "rmarkdown", "knitr", "quarto", "bookdown", "rmdformats"
)

message(sprintf(">>> Installing %d CRAN/Bioc packages ...", length(pkgs)))
pak::pak(pkgs, ask = FALSE)
message(">>> Rest layer complete.")
