# Data-root helper. In this repository the data sit inside each paper folder, so the data root is the repository root.
# Run every script from the repository root. Override the root with the environment variable REPLICATEME_DATA.
DATA_ROOT <- normalizePath(Sys.getenv("REPLICATEME_DATA", if (requireNamespace("here", quietly = TRUE)) here::here() else getwd()),
                           winslash = "/", mustWork = FALSE)
dpath <- function(...) file.path(DATA_ROOT, ...)
dscratch <- function(paper, sub, ...) { d <- dpath(paper, sub, "_scratch"); dir.create(d, recursive = TRUE, showWarnings = FALSE); file.path(d, ...) }
