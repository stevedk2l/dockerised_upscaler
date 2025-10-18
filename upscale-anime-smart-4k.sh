#!/bin/bash
# upscale-anime-4k-smart.sh
# High-quality 4K anime upscaling (CPU-only, resumable, separate input/output dirs)

INPUT_DIR="/input"
OUTPUT_DIR="/output"
SUFFIX="_4k"
LOGFILE="$OUTPUT_DIR/upscale.log"
CHECKPOINT_FILE="$OUTPUT_DIR/upscale-checkpoint.txt"
SCALE=${SCALE:-4}
DENOISE=${DENOISE:-2}
FPS_DEFAULT=24
MIN_WIDTH=3840
MIN_HEIGHT=2160

echo "--------------------------------------------"
echo "🟢 Starting Smart 4K Upscale Job"
echo "Input: $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo "Scale: ${SCALE}× | Denoise: ${DENOISE}"
echo "Checkpoint: $CHECKPOINT_FILE"
echo "--------------------------------------------"

mkdir -p "$OUTPUT_DIR"
touch "$CHECKPOINT_FILE"

declare -A DONE
while read -r line; do
  DONE["$line"]=1
done < "$CHECKPOINT_FILE"

find "$INPUT_DIR" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) | while read -r FILE; do
  REL_PATH="${FILE#$INPUT_DIR/}"
  BASENAME=$(basename "$FILE")
  DIRNAME=$(dirname "$REL_PATH")
  NAME="${BASENAME%.*}"
  EXT="${BASENAME##*.}"
  OUTDIR="$OUTPUT_DIR/$DIRNAME"
  OUTFILE="$OUTDIR/${NAME}${SUFFIX}.${EXT}"

  mkdir -p "$OUTDIR"

  if [ "${DONE["$FILE"]}" ] || [ -f "$OUTFILE" ]; then
    echo "⏭️ Skipping (already done): $BASENAME" | tee -a "$LOGFILE"
    continue
  fi

  # Get input resolution
  RES=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
        -of csv=p=0:s=x "$FILE")
  WIDTH=$(echo "$RES" | cut -d'x' -f1)
  HEIGHT=$(echo "$RES" | cut -d'x' -f2)

  if [ "$WIDTH" -ge "$MIN_WIDTH" ] && [ "$HEIGHT" -ge "$MIN_HEIGHT" ]; then
    echo "🟡 Skipping (already 4K or higher): $BASENAME ($WIDTH×$HEIGHT)" | tee -a "$LOGFILE"
    echo "$FILE" >> "$CHECKPOINT_FILE"
    continue
  fi

  TMPDIR="$OUTDIR/${NAME}_frames"
  mkdir -p "$TMPDIR"

  echo "🎞️ Extracting frames from $BASENAME ($WIDTH×$HEIGHT)" | tee -a "$LOGFILE"
  ffmpeg -loglevel error -i "$FILE" -qscale:v 1 "$TMPDIR/frame_%06d.png"

  echo "🧠 Upscaling frames with waifu2x-caffe (CPU mode)" | tee -a "$LOGFILE"
  find "$TMPDIR" -name "*.png" | parallel -j$(nproc) /usr/local/bin/waifu2x-caffe/waifu2x-caffe \
    -i {} -o {} \
    -p cpu -s $SCALE -n $DENOISE \
    --model_dir /usr/local/bin/waifu2x-caffe/models/anime_style_art_rgb

  echo "🎬 Rebuilding 4K video $OUTFILE" | tee -a "$LOGFILE"
  ffmpeg -loglevel error -r $FPS_DEFAULT -i "$TMPDIR/frame_%06d.png" -i "$FILE" \
    -map 0:v -map 1:a? -map 1:s? \
    -vf "scale=3840:2160:flags=lanczos" \
    -c:v libx265 -crf 18 -preset slow -pix_fmt yuv420p \
    -c:a copy -c:s copy "$OUTFILE"

  echo "$FILE" >> "$CHECKPOINT_FILE"
  rm -rf "$TMPDIR"
  echo "✅ Completed: $OUTFILE" | tee -a "$LOGFILE"
done

echo "--------------------------------------------"
echo "🏁 All files processed. Log saved at $LOGFILE"
echo "--------------------------------------------"

