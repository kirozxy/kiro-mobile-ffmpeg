#!/usr/bin/env bash
# Build the compact MobileFFmpeg native libraries with Android NDK r28+.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
ndk=${ANDROID_NDK_ROOT:?Set ANDROID_NDK_ROOT to Android NDK r28 or newer}
case $(uname -s) in
  Linux) host=linux-x86_64 ;;
  Darwin) host=darwin-x86_64 ;;
  MINGW*|MSYS*|CYGWIN*) host=windows-x86_64; ndk=$(cygpath -u "$ndk") ;;
  *) echo "Unsupported build host" >&2; exit 1 ;;
esac
toolchain="$ndk/toolchains/llvm/prebuilt/$host"
[[ -d "$toolchain/bin" ]] || { echo "NDK LLVM toolchain not found: $toolchain" >&2; exit 1; }
export PATH="$toolchain/bin:$PATH"
src="$root/src/ffmpeg"
wrapper="$root/android/app/src/main/cpp"
cpu="$root/android/jni/cpufeatures"
out=${BUILD_OUTPUT_DIR:-"$root/.native-build"}
jobs=${JOBS:-8}
api=21
alignment='-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384'

build_abi() {
  local abi=$1 target arch cpu_arch define
  local -a asm
  case "$abi" in
    arm64-v8a) target=aarch64-linux-android; arch=aarch64; cpu_arch=armv8-a; define=ARM64_V8A; asm=(--enable-asm --enable-inline-asm --enable-neon) ;;
    armeabi-v7a) target=armv7a-linux-androideabi; arch=arm; cpu_arch=armv7-a; define=ARM_V7A; asm=(--enable-asm --enable-inline-asm --enable-neon) ;;
    x86) target=i686-linux-android; arch=x86; cpu_arch=i686; define=X86; asm=(--disable-asm) ;;
    x86_64) target=x86_64-linux-android; arch=x86_64; cpu_arch=x86_64; define=X86_64; asm=(--enable-asm --enable-inline-asm --disable-x86asm) ;;
    *) echo "Unsupported Android ABI: $abi" >&2; return 1 ;;
  esac
  local work="$out/ffmpeg/$abi" dest="$out/jni/$abi"
  mkdir -p "$work" "$dest"
  local cc="clang --target=${target}${api}" cxx="clang++ --target=${target}${api}"
  echo "Building $abi with $cc"
  (
    cd "$work"
    if [[ ${REUSE_CONFIG:-0} != 1 || ! -f ffbuild/config.mak ]]; then
      bash "$src/configure" \
      --arch="$arch" --cpu="$cpu_arch" --target-os=android \
      --cc="$cc" --cxx="$cxx" --ld="$cc" --ar=llvm-ar --nm=llvm-nm \
      --ranlib=llvm-ranlib --strip=llvm-strip --pkg-config=false \
      --enable-cross-compile --enable-version3 --enable-pic --enable-jni \
      --enable-shared --disable-static --disable-programs --enable-ffmpeg --enable-ffprobe --disable-doc \
      --disable-everything --disable-autodetect --enable-small --disable-debug --disable-lto \
      --enable-protocol=file --enable-muxer=wav --enable-demuxer=mmf --enable-demuxer=wav \
      --enable-decoder=adpcm_ima_wav --enable-decoder=adpcm_yamaha --enable-encoder=pcm_u8 \
      --enable-filter=aresample --disable-sdl2 --disable-zlib \
      "${asm[@]}" \
      --extra-cflags="-Os -DBIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD" --extra-ldflags="$alignment"
    fi
    # Enabling ffmpeg and ffprobe retains their required filters and feature
    # selections. Only ship the libraries; the Java wrapper provides the CLI.
    make -j"$jobs" libavcodec/libavcodec.so libavdevice/libavdevice.so \
      libavfilter/libavfilter.so libavformat/libavformat.so libavutil/libavutil.so \
      libswresample/libswresample.so libswscale/libswscale.so
    for lib in avcodec avdevice avfilter avformat avutil swresample swscale; do
      cp -L "lib$lib/lib$lib.so" "$dest/lib$lib.so"
    done
  )
  # Build the legacy Android ABI detection and wrapper using the same FFmpeg config.
  local -a common=(--target="${target}${api}" -shared -fPIC -Os -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384)
  clang "${common[@]}" -Wl,-soname,libcpufeatures.so "$cpu/cpu-features.c" -ldl -o "$dest/libcpufeatures.so"
  clang "${common[@]}" -Wl,-soname,libmobileffmpeg_abidetect.so -DMOBILE_FFMPEG_"$define" \
    -I"$cpu" -I"$work" -I"$src" "$wrapper/mobileffmpeg_abidetect.c" -L"$dest" -lcpufeatures -llog -lz -landroid \
    -o "$dest/libmobileffmpeg_abidetect.so"
  clang "${common[@]}" -Wl,-soname,libmobileffmpeg.so -I"$work" -I"$src" -DMOBILE_FFMPEG_BUILD_DATE="$(date +%Y%m%d)" \
    "$wrapper/mobileffmpeg.c" "$wrapper/mobileffprobe.c" "$wrapper/mobileffmpeg_exception.c" \
    "$wrapper/fftools_cmdutils.c" "$wrapper/fftools_ffmpeg.c" "$wrapper/fftools_ffprobe.c" \
    "$wrapper/fftools_ffmpeg_opt.c" "$wrapper/fftools_ffmpeg_hw.c" "$wrapper/fftools_ffmpeg_filter.c" \
    -L"$dest" -lavfilter -lavformat -lavcodec -lavutil -lswresample -lavdevice -lswscale -llog -lz -landroid -lm -ldl \
    -o "$dest/libmobileffmpeg.so"
  llvm-strip --strip-unneeded "$dest"/*.so
}

if (($# == 0)); then
  set -- arm64-v8a armeabi-v7a x86 x86_64
fi
for abi in "$@"; do
  build_abi "$abi"
done
