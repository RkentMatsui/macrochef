#!/usr/bin/env bash
# Downloads the bundled sherpa-onnx voice models into assets/models/.
#   ASR: Whisper base.en (int8) + Silero VAD   TTS: vits-ljs
# Requires curl + python3/python.
set -euo pipefail
cd "$(dirname "$0")/.."

ASR_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-base.en.tar.bz2"
VAD_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"
TTS_URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-ljs.tar.bz2"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN=python
else
  echo "python3 or python is required to extract .tar.bz2 voice model archives." >&2
  exit 1
fi

extract_tar_bz2() {
  "$PYTHON_BIN" - "$1" <<'PY'
import os
import sys
import tarfile

archive_path = sys.argv[1]
destination = os.path.realpath(".")

with tarfile.open(archive_path, "r:bz2") as archive:
    for member in archive.getmembers():
        target = os.path.realpath(os.path.join(destination, member.name))
        if os.path.commonpath([destination, target]) != destination:
            raise RuntimeError(f"Refusing to extract unsafe path: {member.name}")
    archive.extractall(destination)
PY
}

# Clean + recreate so removing the old streaming-zipformer files is automatic.
rm -rf assets/models .voice_tmp
mkdir -p assets/models/asr assets/models/tts .voice_tmp
cd .voice_tmp

echo "Downloading Whisper base.en..."; curl -L -o whisper.tar.bz2 "$ASR_URL"
echo "Downloading Silero VAD...";       curl -L -o silero_vad.onnx "$VAD_URL"
echo "Downloading TTS (vits-ljs)...";   curl -L -o tts.tar.bz2 "$TTS_URL"
echo "Extracting..."
extract_tar_bz2 whisper.tar.bz2
extract_tar_bz2 tts.tar.bz2

WH="sherpa-onnx-whisper-base.en"
cp "$WH/base.en-encoder.int8.onnx" ../assets/models/asr/base.en-encoder.int8.onnx
cp "$WH/base.en-decoder.int8.onnx" ../assets/models/asr/base.en-decoder.int8.onnx
cp "$WH/base.en-tokens.txt"        ../assets/models/asr/base.en-tokens.txt
cp silero_vad.onnx                 ../assets/models/asr/silero_vad.onnx

cp vits-ljs/vits-ljs.onnx  ../assets/models/tts/vits-ljs.onnx
cp vits-ljs/lexicon.txt    ../assets/models/tts/lexicon.txt
cp vits-ljs/tokens.txt     ../assets/models/tts/tokens.txt

cd ..; rm -rf .voice_tmp
echo "Done. Models in assets/models/. Sizes:"; du -h assets/models/asr/* assets/models/tts/*
