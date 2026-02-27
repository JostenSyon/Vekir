#!/usr/bin/env bash
set -euo pipefail

# Merge-copy Vekir pack to the Switch SD mounted on macOS.
# Default target volume name matches your setup: "SWITCH SD".
# It merges directories safely (no Finder-style folder replacement).

VOL_NAME="${SWITCH_SD_VOLUME:-SWITCH SD}"
TARGET=""
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REMIX_SRC="${REPO_ROOT}/Vekir/"

MODE="merge"   # merge | only-new
COPY_VENOM=0
VENOM_SRC="${REPO_ROOT}/venom/"  # optional local staging folder
DRYRUN=0
AUTO_EJECT=1

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --volume NAME        macOS volume name (default: "SWITCH SD")
  --only-new           copy only missing files (do not overwrite existing files)
  --copy-venom PATH    also sync PATH to /venom on SD
  --dry-run            show what would be copied
  --no-eject           do not safely unmount/eject the SD volume after copy
  -h, --help           show help

Examples:
  $(basename "$0")
  $(basename "$0") --copy-venom "/path/to/NXVenom pack"
  $(basename "$0") --only-new --dry-run
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --volume)
      VOL_NAME="$2"; TARGET="/Volumes/${VOL_NAME}"; shift 2 ;;
    --only-new)
      MODE="only-new"; shift ;;
    --copy-venom)
      COPY_VENOM=1; VENOM_SRC="$2"; shift 2 ;;
    --dry-run)
      DRYRUN=1; shift ;;
    --no-eject)
      AUTO_EJECT=0; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1 ;;
  esac
done

detect_target() {
  local preferred="/Volumes/${VOL_NAME}"
  if [[ -d "$preferred" ]]; then
    TARGET="$preferred"
    return 0
  fi

  # Fallback: look for mounted volumes containing "SWITCH" (case-insensitive)
  mapfile -t matches < <(find /Volumes -maxdepth 1 -mindepth 1 -type d 2>/dev/null | grep -i '/Volumes/.*SWITCH')
  if [[ ${#matches[@]} -eq 1 ]]; then
    TARGET="${matches[0]}"
    return 0
  fi

  # Secondary fallback: exact-ish prefix/suffix match for requested name
  mapfile -t matches < <(find /Volumes -maxdepth 1 -mindepth 1 -type d 2>/dev/null | grep -i "/Volumes/${VOL_NAME}")
  if [[ ${#matches[@]} -ge 1 ]]; then
    TARGET="${matches[0]}"
    return 0
  fi

  return 1
}

if ! detect_target; then
  echo "SD not found under /Volumes." >&2
  echo "Tried preferred volume: '${VOL_NAME}' and auto-detection for names containing 'SWITCH'." >&2
  echo "Mounted volumes:" >&2
  find /Volumes -maxdepth 1 -mindepth 1 -type d -print 2>/dev/null >&2 || true
  exit 1
fi

if [[ ! -d "$REMIX_SRC" ]]; then
  echo "Remix source not found: $REMIX_SRC" >&2
  exit 1
fi

cleanup_macos_junk() {
  local root="$1"
  local removed=0

  if [[ $DRYRUN -eq 1 ]]; then
    echo "==> Dry-run: skipping macOS junk cleanup on target"
    return 0
  fi

  echo "==> Cleaning stale macOS junk files on target (.DS_Store, ._*, __MACOSX)"
  for d in "$root/bootloader" "$root/switch" "$root/config" "$root/venom"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' f; do
      rm -f "$f"
      removed=$((removed + 1))
    done < <(find "$d" -type f \( -name '.DS_Store' -o -name '._*' \) -print0 2>/dev/null)
    while IFS= read -r -d '' p; do
      rm -rf "$p"
      removed=$((removed + 1))
    done < <(find "$d" -type d -name '__MACOSX' -print0 2>/dev/null)
  done
  echo "==> Removed $removed junk entries"
}

RSYNC_FLAGS=( -aiv --exclude '.DS_Store' --exclude '._*' )
if [[ "$MODE" == "only-new" ]]; then
  RSYNC_FLAGS+=( --ignore-existing )
fi
if [[ $DRYRUN -eq 1 ]]; then
  RSYNC_FLAGS+=( --dry-run )
fi

cleanup_macos_junk "$TARGET"

# Merge the remix pack into SD root (bootloader/, config/, switch/ ...)
echo "==> Syncing Vekir -> $TARGET"
rsync "${RSYNC_FLAGS[@]}" "$REMIX_SRC" "$TARGET/"

# Optional: copy a full Venom pack (or any folder) into /venom without touching SD root
if [[ $COPY_VENOM -eq 1 ]]; then
  if [[ ! -d "$VENOM_SRC" ]]; then
    echo "Venom source not found: $VENOM_SRC" >&2
    exit 1
  fi
  echo "==> Syncing Venom source -> $TARGET/venom"
  mkdir -p "$TARGET/venom"
  rsync "${RSYNC_FLAGS[@]}" "$VENOM_SRC/" "$TARGET/venom/"
fi

cleanup_macos_junk "$TARGET"

echo "Done. Mode: $MODE"

safe_eject() {
  local target_path="$1"
  local disk_id=""
  local parent_disk_id=""

  if [[ $DRYRUN -eq 1 ]]; then
    echo "==> Dry-run: skipping eject"
    return 0
  fi

  if [[ $AUTO_EJECT -eq 0 ]]; then
    echo "==> Auto-eject disabled (--no-eject)"
    return 0
  fi

  echo "==> Flushing writes..."
  sync || true
  sleep 1

  echo "==> Safely unmounting/ejecting $target_path"
  if command -v diskutil >/dev/null 2>&1; then
    # Resolve identifiers so we can eject the parent physical device (better for Hekate UMS).
    disk_id="$(diskutil info "$target_path" 2>/dev/null | awk -F': *' '/Device Identifier/ {print $2; exit}')"
    if [[ -n "$disk_id" ]]; then
      parent_disk_id="$(diskutil info "$target_path" 2>/dev/null | awk -F': *' '/Part of Whole/ {print $2; exit}')"
    fi
    if [[ -z "$parent_disk_id" && -n "$disk_id" ]]; then
      parent_disk_id="${disk_id%s*}" # disk4s1 -> disk4
    fi

    # Unmount first so pending writes complete cleanly.
    diskutil unmount "$target_path" || true
    sleep 1

    # Prefer ejecting the whole disk; fallback to target path.
    if [[ -n "$parent_disk_id" ]] && diskutil eject "$parent_disk_id"; then
      echo "SD ejected safely ($parent_disk_id)."
      sleep 2
      return 0
    fi
    if diskutil eject "$target_path"; then
      echo "SD ejected safely."
      sleep 2
      return 0
    fi
  fi

  echo "Warning: automatic eject failed. Please eject '$target_path' manually." >&2
  return 1
}

safe_eject "$TARGET" || true
