#!/usr/bin/env Rscript
# ============================================================================
# install_destiny.R  --  destiny (diffusion maps for scSLIDE), REQUIRED
#
# destiny imports `smoother`, which was REMOVED from CRAN on 2025-12-19, so it
# can't be resolved from the snapshot's main repo. Install smoother's last
# release (1.3) from the CRAN archive in the SAME solve as destiny, so pak uses
# it to satisfy destiny's dependency. Its own dep (TTR) resolves from CRAN.
#
# Own layer (after the rest) so it rebuilds cheaply via the registry cache.
# ============================================================================

options(
  Ncpus = max(1L, parallel::detectCores()),
  warn  = 1
)

message(">>> Installing destiny (+ archived smoother 1.3) ...")
pak::pak(c(
  "url::https://cran.r-project.org/src/contrib/Archive/smoother/smoother_1.3.tar.gz",
  "destiny"
), ask = FALSE)

if (!("destiny" %in% rownames(installed.packages()))) {
  stop("destiny did not install")
}
message(sprintf(">>> destiny %s installed (diffusion maps available).",
                utils::packageVersion("destiny")))
