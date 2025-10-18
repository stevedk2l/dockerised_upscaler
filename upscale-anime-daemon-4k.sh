#!/bin/bash
# upscale-anime-4k-daemon.sh
# Watches /input for new anime files and upscales to /output automatically.

INPUT_DIR="/input"
OUTPUT_DIR="/output"
SCAN_INTERVAL=${SCAN_INTERVAL:-21600}   # 6 hours by default
RUN_ONCE=${RUN_ONCE:-false}

echo "--------------------------------------------"
echo "🟢 Anime Upscale Watcher Started"
echo "Input dir: $INPUT_DIR"
echo "Output dir: $OUTPUT_DIR"
echo "Scan interval: ${SCAN_INTERVAL}s"
echo "--------------------------------------------"

# Function to run the main upscale job
run_upscale() {
  echo "🔍 Scanning for new files..."
  /usr/local/bin/upscale-anime-smart-4k.sh
  echo "✅ Scan complete at $(date)"
}

# First immediate run
run_upscale

# Loop unless RUN_ONCE=true
if [ "$RUN_ONCE" = "true" ]; then
  echo "⚙️ Run-once mode enabled, exiting."
  exit 0
fi

while true; do
  echo "⏳ Sleeping for ${SCAN_INTERVAL}s..."
  sleep "$SCAN_INTERVAL"
  run_upscale
done

