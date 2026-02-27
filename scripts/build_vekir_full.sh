#!/usr/bin/env bash
set -euo pipefail

# Build Vekir-full.zip starting from a clean Kefir package (dir or zip).
# The output contains:
# - Kefir base files
# - Vekir overlay files
# - an auto-chain in kefir-updater/update.te:
#   Kefir installer -> schedule Vekir apply via TegraExplorer startup.te

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VEKIR_DIR="${ROOT_DIR}/Vekir"
RELEASE_DIR="${ROOT_DIR}/.release"
WORK_DIR="${ROOT_DIR}/.sim/build-vekir-full"

KEFIR_DIR=""
KEFIR_ZIP=""
VERSION_TAG=""

usage() {
  cat <<'USAGE'
Usage:
  build_vekir_full.sh --kefir-dir /path/to/kefir
  build_vekir_full.sh --kefir-zip /path/to/kefir.zip

Options:
  --kefir-dir PATH     Kefir folder root (clean unpacked pack)
  --kefir-zip PATH     Kefir zip file (clean release zip)
  --version TAG        Optional suffix for output name (e.g. 19.0.1)
  -h, --help           Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kefir-dir)
      KEFIR_DIR="$2"; shift 2 ;;
    --kefir-zip)
      KEFIR_ZIP="$2"; shift 2 ;;
    --version)
      VERSION_TAG="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
  esac
done

if [[ -n "$KEFIR_DIR" && -n "$KEFIR_ZIP" ]]; then
  echo "Use only one input: --kefir-dir OR --kefir-zip" >&2
  exit 1
fi

if [[ -z "$KEFIR_DIR" && -z "$KEFIR_ZIP" ]]; then
  echo "Missing input: provide --kefir-dir or --kefir-zip" >&2
  exit 1
fi

if [[ ! -d "$VEKIR_DIR" ]]; then
  echo "Missing Vekir dir: $VEKIR_DIR" >&2
  exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/base" "$WORK_DIR/out" "$RELEASE_DIR"

if [[ -n "$KEFIR_ZIP" ]]; then
  if [[ ! -f "$KEFIR_ZIP" ]]; then
    echo "Kefir zip not found: $KEFIR_ZIP" >&2
    exit 1
  fi
  unzip -q "$KEFIR_ZIP" -d "$WORK_DIR/base"
  # Normalize if zip has a single top-level folder
  mapfile -t top_items < <(find "$WORK_DIR/base" -mindepth 1 -maxdepth 1)
  if [[ ${#top_items[@]} -eq 1 && -d "${top_items[0]}" ]]; then
    rsync -a "${top_items[0]}/" "$WORK_DIR/out/"
  else
    rsync -a "$WORK_DIR/base/" "$WORK_DIR/out/"
  fi
else
  if [[ ! -d "$KEFIR_DIR" ]]; then
    echo "Kefir dir not found: $KEFIR_DIR" >&2
    exit 1
  fi
  rsync -a "$KEFIR_DIR/" "$WORK_DIR/out/"
fi

# Overlay Vekir content on top of Kefir pack
rsync -a --exclude '.DS_Store' --exclude '._*' "$VEKIR_DIR/" "$WORK_DIR/out/"

UPDATE_TE="$WORK_DIR/out/switch/kefir-updater/update.te"
if [[ ! -f "$UPDATE_TE" ]]; then
  echo "Missing Kefir updater script in base pack: $UPDATE_TE" >&2
  exit 1
fi

MARK_BEGIN="# VEKIR AUTO-CHAIN BEGIN"
MARK_END="# VEKIR AUTO-CHAIN END"

if ! grep -q "$MARK_BEGIN" "$UPDATE_TE"; then
  awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
    /# 5\. .*гекату/ && !done {
      print ""
      print begin
      print "if (fsexists(\"sd:/switch/vekir/apply_remix.te\")) {"
      print "  delfile(\"sd:/startup.te\")"
      print "  copyfile(\"sd:/switch/vekir/apply_remix.te\", \"sd:/startup.te\")"
      print "  if (fsexists(\"sd:/bootloader/payloads/TegraExplorer.bin\")) {"
      print "    delfile(\"sd:/payload.bin\")"
      print "    copyfile(\"sd:/bootloader/payloads/TegraExplorer.bin\", \"sd:/payload.bin\")"
      print "  }"
      print "  p(\"Vekir post-install apply scheduled\")"
      print "}"
      print end
      print ""
      done=1
    }
    { print }
  ' "$UPDATE_TE" > "${UPDATE_TE}.tmp"
  mv "${UPDATE_TE}.tmp" "$UPDATE_TE"
fi

if ! grep -q "$MARK_BEGIN" "$UPDATE_TE"; then
  echo "Failed to inject Vekir auto-chain into: $UPDATE_TE" >&2
  exit 1
fi

OUT_NAME="Vekir-full.zip"
if [[ -n "$VERSION_TAG" ]]; then
  OUT_NAME="Vekir-full-${VERSION_TAG}.zip"
fi
OUT_PATH="$RELEASE_DIR/$OUT_NAME"
rm -f "$OUT_PATH"

(
  cd "$WORK_DIR/out"
  zip -r "$OUT_PATH" . -x "*.DS_Store" "__MACOSX/*" "*/._*" >/dev/null
)

echo "Built: $OUT_PATH"
ls -lh "$OUT_PATH"
