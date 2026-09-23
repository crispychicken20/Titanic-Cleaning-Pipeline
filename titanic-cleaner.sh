set -e
set -euo pipefail

INPUT="$1"
OUTPUT="${2:-titanic-clean.csv}"

# --- check the input before doing anything ---
if [[ ! -r "$INPUT" ]]; then
	echo "Error: cannot read $INPUT" >&2
	exit 1
fi

#create a temporary file
tmp="$(mktemp)"

#remove temp file when script excutes
trap 'rm -f "$tmp"' EXIT

# CLEAN THE DATASET
awk '{ sub(/\r$/, ""); print }' "$INPUT" > "$OUTPUT"
sed -E \
    -e 's/,mae,/,male,/' \
    -e 's/^("[^"]*"),,([^,]+),/\1,NA,\2,/' \
    "$INPUT" > "$tmp"
# REMOVE DUPLICATES
awk '!seen[$0]++' "$tmp" > "$OUTPUT"

echo "...Cleaning complete."
echo "Cleaned file: $OUTPUT"
