"""Data-root helper: dpath('P18_FvFS', 'original', ...) -> <repository root>/P18_FvFS/original/... (run from the repository root)."""
import os
DATA_ROOT = os.environ.get("REPLICATEME_DATA", os.getcwd())
def dpath(*parts):
    return os.path.join(DATA_ROOT, *parts)
