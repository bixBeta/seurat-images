# trex-sc — reproducible Seurat v5 single-cell image

One image, two modes: **RStudio Server** for interactive work and
**command-line R** for multi-day batch jobs. Built for reproducible
SCTransform / integration results while keeping the rest of the stack current.

## What's pinned vs floating

| Layer | Choice | Why |
|---|---|---|
| R | 4.4.0 | Newest R that cleanly carries the Seurat 5.0.0 ecosystem **and** qs2 |
| Bioconductor | 3.20 | Matches R 4.4; in sync with the CRAN freeze; carries qs2 |
| CRAN | frozen @ 2024-11-01 (PPM snapshot) | Deterministic rebuilds |
| Seurat | **5.0.0 (pinned)** | Reproduce prior clustering/SCT output |
| SeuratObject | floats to 5.0.x | Only >=5.0.0 required; patch level doesn't affect results |
| sctransform | **0.4.1 (pinned)** | Governs SCT numerics |
| Signac | **1.12.0 (pinned)** | Reproduce ATAC/multiome behaviour |
| glmGamPoi | floats to 1.16.x | Bioc-locked; numerically equivalent for SCT |
| everything else | snapshot-stable | Your "update the rest" choice |
| qs2, Air, Quarto | current | The tooling you asked for |

## Build

Keep `Dockerfile` and `install_packages.R` in the same directory, then:

```bash
docker build -t trex-sc:1.0 .
```

First build is long (compiles a few packages); rebuilds are cached. The
build **verifies the four pins** at the end and prints `ok`/`MISMATCH` per
package.

## Run — RStudio Server (interactive)

```bash
docker run --rm -d -p 8787:8787 \
  -e PASSWORD=changeme \
  -v "$PWD":/home/rstudio/project \
  trex-sc:1.0
# open http://localhost:8787   user: rstudio   pass: changeme
```

## Run — command-line R (multi-day jobs)

```bash
# detached, survives disconnect
docker run --rm -d \
  -v "$PWD":/work -w /work \
  trex-sc:1.0 Rscript 03a_integration_cca.R
```

### On HPC via Singularity

For SLURM/HPC batch work, convert the Docker image to a `.sif` and run R
directly — no RStudio needed:

```bash
singularity build trex-sc.sif docker-daemon://trex-sc:1.0
singularity exec --bind /SSD:/SSD trex-sc.sif Rscript 03a_integration_cca.R
```

## Air (R formatter)

`air` is on the PATH inside the image for both modes:

```bash
air format .            # format every .R file in the project
air format script.R     # one file
```

Drop an `.air.toml` at the project root to set house style (line width, etc.).

**IDE format-on-save caveat:** the RStudio Server version bundled in
`rocker/rstudio:4.4.0` predates native Air integration (that landed in
RStudio 2024.12+). The `air` **CLI works regardless** — wire it into a
pre-commit hook or a Makefile target. If you want format-on-save inside the
baked RStudio, bump the base image to a newer `rocker/rstudio` tag and
rebuild.

## Notes & knobs

- **SeuratObject is floated, not pinned.** Pinning it to the exact 5.0.0
  patch made the dependency graph unsolvable, so it resolves to 5.0.x
  (currently 5.0.2). Seurat 5.0.0 only needs >= 5.0.0, and the patch level
  doesn't change SCTransform / clustering output. The result-governing pins
  (Seurat, sctransform, Signac) are asserted at the end of the build.
- **Adding packages.** Append to `pkgs` (CRAN or Bioc — pak auto-detects) or
  `github` in `install_packages.R`, then rebuild. Only direct-use packages
  need listing; dependencies resolve automatically.
- **SeuratData datasets** (e.g. `pbmcsca`) are not baked in — install at
  runtime with `SeuratData::InstallData()` into a mounted volume.
- **Changing the freeze date / R version** means re-checking the pins
  compile; the 2024-11 / R 4.4 / Bioc 3.20 combo was chosen specifically
  because it's where the pinned Seurat family, the floated deps, and qs2
  all coexist.
