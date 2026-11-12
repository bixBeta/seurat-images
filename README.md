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

## Known gap: `destiny` (diffusion maps)

`destiny` is a **secondary** scSLIDE dependency (diffusion-map embeddings). Its own
dependency `smoother` fails to resolve on the current snapshot, so destiny is
installed **best-effort** and is currently **skipped** (`DESTINY_SKIPPED` in the
build log). Seurat v6 + the scSLIDE core (sample objects, PLS, DE) are fully
present. If you need diffusion maps, we can chase the `smoother` fix (install from
CRAN archive or source) and re-enable destiny.

## Pull

```bash
docker1 pull ghcr.io/bixbeta/trex-sc:v6
```

Set the GHCR package **Public** once for login-free pulls (GitHub → `trex-sc`
package → Package settings → visibility), or `docker login ghcr.io` with a PAT.

Run commands (RStudio / CLI / Singularity) are identical to the v5 README on
`main` — just swap the tag to `:v6`.
