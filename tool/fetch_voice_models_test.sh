#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/repo/tool" "$tmp/bin"
cp "$repo/tool/fetch_voice_models.sh" "$tmp/repo/tool/fetch_voice_models.sh"
chmod +x "$tmp/repo/tool/fetch_voice_models.sh"

cat > "$tmp/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
out=
while (($#)); do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
mkdir -p "$(dirname "$out")"
case "$(basename "$out")" in
  whisper.tar.bz2)
    python3 - "$out" <<'PY'
import sys
import tarfile
import tempfile
from pathlib import Path

out = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as td:
    root = Path(td) / "sherpa-onnx-whisper-base.en"
    root.mkdir()
    for name in ("base.en-encoder.int8.onnx", "base.en-decoder.int8.onnx", "base.en-tokens.txt"):
        (root / name).write_text("", encoding="utf-8")
    with tarfile.open(out, "w:bz2") as archive:
        archive.add(root, arcname=root.name)
PY
    ;;
  tts.tar.bz2)
    python3 - "$out" <<'PY'
import sys
import tarfile
import tempfile
from pathlib import Path

out = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as td:
    root = Path(td) / "vits-ljs"
    root.mkdir()
    for name in ("vits-ljs.onnx", "lexicon.txt", "tokens.txt"):
        (root / name).write_text("", encoding="utf-8")
    with tarfile.open(out, "w:bz2") as archive:
        archive.add(root, arcname=root.name)
PY
    ;;
  silero_vad.onnx)
    printf 'vad\n' > "$out"
    ;;
  *)
    echo "unexpected curl output: $out" >&2
    exit 64
    ;;
esac
STUB

cat > "$tmp/bin/bzip2" <<'STUB'
#!/usr/bin/env bash
echo "bzip2 should not be called" >&2
exit 127
STUB

cat > "$tmp/bin/tar" <<'STUB'
#!/usr/bin/env bash
echo "tar should not be called" >&2
exit 2
STUB

cat > "$tmp/bin/du" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB

chmod +x "$tmp/bin/"*

PATH="$tmp/bin:$PATH" bash "$tmp/repo/tool/fetch_voice_models.sh"

test -f "$tmp/repo/assets/models/asr/base.en-encoder.int8.onnx"
test -f "$tmp/repo/assets/models/asr/base.en-decoder.int8.onnx"
test -f "$tmp/repo/assets/models/asr/base.en-tokens.txt"
test -f "$tmp/repo/assets/models/asr/silero_vad.onnx"
test -f "$tmp/repo/assets/models/tts/vits-ljs.onnx"
test -f "$tmp/repo/assets/models/tts/lexicon.txt"
test -f "$tmp/repo/assets/models/tts/tokens.txt"
