# trex-sc — reproducible Seurat v5 single-cell image

One image, two modes: **RStudio Server** for interactive work and
**command-line R** for multi-day batch jobs. Built on CI so the environment is
reproducible and pullable, not hand-assembled on a server.

**Image:** `ghcr.io/bixbeta/trex-sc:1.0` (and `:latest`)
**Source/CI:** `bixBeta/seurat-images` → GitHub Actions builds and pushes to GHCR on every push to `main`.

## What's pinned vs floating

| Layer | Choice | Why |
|---|---|---|
| R | 4.4.0 | Newest R that carries the Seurat 5 stack **and** qs2 |
| Bioconductor | 3.20 | Matches R 4.4; in sync with the CRAN freeze; carries qs2 |
| CRAN | frozen @ 2024-11-01 (PPM snapshot) | Deterministic rebuilds |
| sctransform | **0.4.1 (pinned)** | Governs SCTransform numerics |
| Signac | **1.12.0 (pinned)** | ATAC / multiome reproducibility |
| Seurat / SeuratObject | float on the **5.x** line | Exact 5.0.0 pin was unsolvable vs a 2024-11 universe; SCT output is driven by sctransform (pinned) + glmGamPoi, not Seurat's minor version |
| everything else | snapshot-stable | Updated, as requested |
| qs2, Air, Quarto | current | The tooling you asked for |

## Build layout

The install is split into two Docker layers so iterating is cheap:

- **`install_cran.R`** — pinned sctransform/Signac + ~130 CRAN/Bioc packages (the long pole, ~14 min). Verifies the pins and that Seurat is on the 5.x line.
- **`install_github.R`** — GitHub-only extras (presto, SeuratData, SeuratDisk, SeuratWrappers, Azimuth, BPCells, loupeR). **Best-effort**: installed as one solve so cross-deps (Azimuth → SeuratData/SeuratDisk) resolve, with a per-package fallback; any failure is logged as `GITHUB_FAILURES:` but never fails the image. BPCells is pulled from its `r/` subdirectory (`bnprks/BPCells/r`).

System build tools in the image: `curl`, `ca-certificates`, `patch`, `pkg-config`, `cmake`, plus the HDF5 / GSL / GEOS / graphics libraries the single-cell stack needs. CI uses a **registry build cache** in GHCR (not the 10 GB-capped gha cache).

## Pull it (Cornell BioHPC)

```bash
docker1 pull ghcr.io/bixbeta/trex-sc:1.0
```

If the pull asks for auth, the GHCR package is still private — set it **Public** once (GitHub → your `trex-sc` package → Package settings → Change visibility → Public) for login-free pulls, or `docker login ghcr.io` on the server with a PAT.

## Run — RStudio Server (interactive)

```bash
docker1 run -d -p 8787:8787 \
  -e PASSWORD=changeme \
  -e USERID=$(id -u) -e GROUPID=$(id -g) \   # files land owned by you, no chmod 777
  -v /SSD/fa286/project:/home/rstudio/project \
  ghcr.io/bixbeta/trex-sc:1.0
# open http://<host>:8787   user: rstudio
```

Add `-e ROOT=true` if you want passwordless `sudo` inside the IDE.

## Run — command-line R (multi-day jobs)

```bash
docker1 run -d -u 0 -v /SSD/fa286/project:/work -w /work \
  ghcr.io/bixbeta/trex-sc:1.0 Rscript 03a_integration_cca.R
```

### On HPC via Singularity

```bash
singularity build trex-sc.sif docker://ghcr.io/bixbeta/trex-sc:1.0
singularity exec --bind /SSD:/SSD trex-sc.sif Rscript 03a_integration_cca.R
```

Singularity runs as your own user, so bind-mounted paths are read/written as you — no sudo, no `chmod 777`.

## Air (R formatter)

`air` is on the PATH for both modes:

```bash
air format .          # format every .R file
air format script.R   # one file
```

Drop an `.air.toml` at the project root for house style. (IDE format-on-save needs RStudio 2024.12+; the CLI works regardless.)

## Notes

- **Seurat reports 5.x, not 5.0.0.** sctransform (pinned 0.4.1) + glmGamPoi govern SCT numerics, so results stay comparable; the verify step asserts Seurat is on the 5 line.
- **Azimuth** is included via the one-solve GitHub install. If a future rebuild logs it under `GITHUB_FAILURES:`, the image still ships; install it at runtime or re-run the build.
- **Adding packages:** append to `pkgs` in `install_cran.R` (CRAN or Bioc — pak auto-detects) or to `github` in `install_github.R`, push, and CI rebuilds. The `paths` filter watches `Dockerfile`, `install_cran.R`, `install_github.R`, and the workflow.
- **SeuratData datasets** aren't baked in — `SeuratData::InstallData()` into a mounted volume at runtime.
