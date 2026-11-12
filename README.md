# trex-sc v6 — Seurat v6 + scSLIDE single-cell image

Branch `seurat-v6`. Same RStudio-Server + command-line-R image as the v5 build on
`main`, but tracking **Seurat v6.0.0** (installed from GitHub — not yet on CRAN),
which ships the **scSLIDE** sample-level workflow natively.

**Image:** `ghcr.io/bixbeta/trex-sc:v6`
**CI:** push to `seurat-v6` → GitHub Actions (`build-image-v6`) → GHCR.

## What's in it

- **Seurat 6.0.0** (`satijalab/seurat@v6.0.0`) with native scSLIDE:
  `PrepareSampleObject`, `GenerateSampleObject`, `RunPLS`, `SketchDataByGroup`,
  `FindmmNN`/`FindsmNN`, `NormalizeChiSquared`, … — no separate scSLIDE package.
- scSLIDE method deps: `glmGamPoi`, `pls`, `spls` (for `RunPLS`).
- The full single-cell / DE / annotation / viz / Shiny stack, GitHub extras
  (presto, SeuratData, SeuratDisk, SeuratWrappers, Azimuth, BPCells, loupeR),
  plus qs2, Quarto, and Air — same as v5.
- Base: `rocker/rstudio:4.5.1`; current CRAN snapshot; distro-aware PPM binaries.

## Build layout (layered for fast starts)

1. **`install_seurat.R`** — Seurat v6 ecosystem + scSLIDE deps (the early layer, so
   you can start working before the rest finishes).
2. **`install_rest.R`** — the rest of the CRAN/Bioc stack.
3. **`install_github.R`** — GitHub extras, best-effort.
4. **`install_destiny.R`** — destiny (diffusion maps), in its own final layer.

## destiny (diffusion maps) — included

`destiny` (diffusion-map embeddings for scSLIDE) is installed. Its dependency
`smoother` was removed from CRAN on 2025-12-19, so it's pulled from the CRAN
**archive** (smoother 1.3) in the same solve as destiny. destiny lives in its own
final Docker layer so it rebuilds in seconds against the registry cache.

## Pull

```bash
docker1 pull ghcr.io/bixbeta/trex-sc:v6
```

Set the GHCR package **Public** once for login-free pulls (GitHub → `trex-sc`
package → Package settings → visibility), or `docker login ghcr.io` with a PAT.

Run commands (RStudio / CLI / Singularity) are identical to the v5 README on
`main` — just swap the tag to `:v6`.
