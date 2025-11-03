#!/usr/bin/env zsh
set -euo pipefail

# ---- usage & args -----------------------------------------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <escoria_docs_path>"
  exit 1
fi

escoria_docs="$1"

# Normalize to absolute path for safety
if [[ ! "$escoria_docs" = /* ]]; then
  escoria_docs="$(cd "$(dirname "$escoria_docs")" && pwd)/$(basename "$escoria_docs")"
fi

# ---- step 1: run Godot doctool from current directory -----------------------
# Path contains a space; quote it rather than escaping.
godot_bin="/Applications/Godot 4.3.app/Contents/MacOS/Godot"

if [[ ! -x "$godot_bin" ]]; then
  echo "Error: Godot binary not found at: $godot_bin"
  exit 1
fi

echo "Running Godot doctool..."
"$godot_bin" \
  --doctool ./docs \
  --gdscript-docs res://addons/escoria-core/ \
  --headless --quit --quiet 2>/dev/null

# ---- step 2: copy ./docs -> <escoria_docs>/docsource (overwrite fully) -----
echo "Syncing ./docs -> \"$escoria_docs/docsource\" (overwriting)..."

# Ensure destination parent exists
mkdir -p "$escoria_docs"

# If rsync is available, prefer it for a clean overwrite with --delete
if command -v rsync >/dev/null 2>&1; then
  # Trailing slashes make rsync copy the *contents* of ./docs into docsource
  rsync -a --delete "./docs/" "$escoria_docs/docsource/"
else
  # Fallback: remove and copy
  rm -rf "$escoria_docs/docsource"
  mkdir -p "$escoria_docs/docsource"
  cp -R ./docs/. "$escoria_docs/docsource/"
fi

# ---- step 3: cd into escoria_docs ------------------------------------------
echo "Changing directory to \"$escoria_docs\"..."
cd "$escoria_docs"

# ---- step 4: run docker command --------------------------------------------
echo "Running Docker extract step..."
docker run --rm \
  -v "$(pwd)":/app \
  -v ./scripting:/app/scripting \
  python-esc \
  python extractesc-g4.py

# ---- step 5: run build.sh ---------------------------------------------------
if [[ ! -x "./build.sh" ]]; then
  echo "Error: ./build.sh not found or not executable in \"$escoria_docs\""
  exit 1
fi

echo "Running build.sh..."
./build.sh

# ---- step 6: serve _build via http.server -----------------------------------
if [[ ! -d "_build" ]]; then
  echo "Error: _build directory not found after build."
  exit 1
fi

echo "Serving _build at http://localhost:8000 ..."
echo "(Press Ctrl+C to stop)"
python3 -m http.server --directory _build

