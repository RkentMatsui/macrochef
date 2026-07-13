# Vendored `libonnxruntime.so` (voice/nutrition onnxruntime conflict fix)

`arm64-v8a/libonnxruntime.so` is **sherpa_onnx's** onnxruntime (currently
onnxruntime **1.24.3**, from `sherpa_onnx_android_arm64` 1.13.2).

## Why it's here

Two plugins ship a `libonnxruntime.so`:

- **`sherpa_onnx`** (on-device voice) — its `libsherpa-onnx-c-api.so` is linked
  against onnxruntime **1.24.3** and needs the *versioned* symbol
  `OrtGetApiBase@VERS_1.24.3`.
- **`onnxruntime`** (standalone Dart package, used by the nutrition-RAG MiniLM
  embedder) — ships onnxruntime **1.15.1** (`OrtGetApiBase@VERS_1.15.1`).

An APK can only contain one `libonnxruntime.so` per ABI. Gradle's
`packaging.jniLibs.pickFirsts += "**/libonnxruntime.so"` (see
`android/app/build.gradle.kts`) picks the first in merge order, which was the
`onnxruntime` package's 1.15.1 build — so sherpa couldn't resolve
`OrtGetApiBase@VERS_1.24.3` and **the voice engine failed to load**
(`dlopen: cannot locate symbol "OrtGetApiBase"`).

The **app module's** `jniLibs` are merged *first*, so placing sherpa's lib here
makes `pickFirst` choose it. Both features then work off one lib:

- Voice (sherpa) finds `OrtGetApiBase@VERS_1.24.3`. ✓
- The `onnxruntime` Dart package looks the symbol up **unversioned**
  (`DynamicLibrary.lookup`) and onnxruntime's C API is backward-compatible, so it
  works against sherpa's newer 1.24.3 lib. ✓

## Maintenance

This lib is **coupled to the `sherpa_onnx` version**. If you bump `sherpa_onnx`,
refresh this file from the pub cache and re-verify the symbol version matches
`libsherpa-onnx-c-api.so`:

```bash
cp "$PUB_CACHE/hosted/pub.dev/sherpa_onnx_android_arm64-<ver>/android/src/main/jniLibs/arm64-v8a/libonnxruntime.so" \
   android/app/src/main/jniLibs/arm64-v8a/libonnxruntime.so
# verify: llvm-nm -D libonnxruntime.so | grep OrtGetApiBase  → must match sherpa's VERS_x
```

Only `arm64-v8a` is vendored (every real device); on other ABIs (emulators /
legacy 32-bit) voice may not init, which is harmless (no real mic there).
