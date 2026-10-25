#!/usr/bin/env bash
#
# install.sh — installs sparkly_lite into a virtual environment inside this folder.
#
# Everything this script does, in order:
#   [1/4] Checks that you are on an Apple Silicon Mac (sparkly_lite is built for arm64 only).
#   [2/4] Checks that python3 exists and is version 3.9 or newer.
#   [3/4] Creates a virtual environment in .venv/ (a private Python that lives in
#         this folder) and installs sparkly_lite into it from the .whl file included
#         here, along with its only two dependencies: numpy and pyarrow. It also
#         updates pip and wheel inside .venv/. These four packages are downloaded
#         from the official Python package index (pypi.org). Running the script
#         again installs fresh copies of sparkly_lite and its dependencies.
#   [4/4] Runs a short test, sparkly-lite smoke, which performs a search on two records.
#
# What this script does NOT do: it does not use sudo, does not ask for your password,
# does not touch your system Python or your shell profile (.zshrc), does not modify any
# file outside this folder, and downloads nothing except the four packages named above.
#
# To undo everything this script did:  rm -rf .venv
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

echo "[1/4] checking your machine"
if [ "$(uname)" != "Darwin" ] || [ "$(uname -m)" != "arm64" ]; then
  echo >&2
  echo "ERROR: sparkly_lite needs an Apple Silicon Mac (macOS, arm64)." >&2
  echo "       This machine reports: $(uname) $(uname -m)." >&2
  echo "       Intel Macs, Windows, and Linux are not supported." >&2
  exit 1
fi
echo "      OK — Apple Silicon Mac ($(uname -m), macOS $(sw_vers -productVersion))"

echo "[2/4] checking Python"
if ! command -v python3 >/dev/null 2>&1; then
  echo >&2
  echo "ERROR: python3 was not found on your machine." >&2
  echo "       Download Python 3.12 from https://www.python.org/downloads/macos/," >&2
  echo "       run its installer, and then run this script again." >&2
  exit 1
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)'; then
  echo >&2
  echo "ERROR: sparkly_lite needs Python 3.9 or newer." >&2
  echo "       Found: $(python3 --version) at $(command -v python3)" >&2
  echo "       Download Python 3.12 from https://www.python.org/downloads/macos/," >&2
  echo "       run its installer, and then run this script again." >&2
  exit 1
fi
echo "      OK — $(python3 --version) at $(command -v python3)"

echo "[3/4] creating .venv and installing sparkly_lite (+ numpy, pyarrow)"
python3 -m venv .venv
.venv/bin/python -m pip install -U pip wheel >/dev/null
.venv/bin/python -m pip install --force-reinstall "$HERE"/sparkly_lite-*.whl
echo "      OK — installed into $HERE/.venv"

echo "[4/4] smoke test"
.venv/bin/sparkly-lite smoke

cat <<'EOF'

──────────────────────────────────────────────────────────────────────
 Installation complete.

 Next, turn on the environment (do this once per terminal window):

     source .venv/bin/activate

 Then run your first blocking job:

     sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet

 The tutorial is doc/tutorial.md.
──────────────────────────────────────────────────────────────────────
EOF
