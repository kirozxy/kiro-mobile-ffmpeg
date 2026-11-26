#!/usr/bin/env python3
"""Package rebuilt native libraries with the unchanged MobileFFmpeg Java API."""
import argparse
import pathlib
import re
import struct
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
ABIS = ("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
LIBRARIES = (
    "libavcodec.so", "libavdevice.so", "libavfilter.so", "libavformat.so",
    "libavutil.so", "libcpufeatures.so", "libmobileffmpeg.so",
    "libmobileffmpeg_abidetect.so", "libswresample.so", "libswscale.so",
)


def verify_elf(data, name):
    if data[:4] != b"\x7fELF" or data[5] != 1:
        raise ValueError(f"Not a little-endian ELF: {name}")
    elf64 = data[4] == 2
    header = struct.unpack_from("<HHIQQQIHHHHHH" if elf64 else "<HHIIIIIHHHHHH", data, 16)
    ph_format = "<IIQQQQQQ" if elf64 else "<IIIIIIII"
    segments = [struct.unpack_from(ph_format, data, header[4] + i * header[8])
                for i in range(header[9])]
    loads = [p for p in segments if p[0] == 1]
    if not loads or any(p[-1] < 16384 for p in loads):
        raise ValueError(f"Unaligned PT_LOAD segment: {name}")
    for p in loads:
        offset, vaddr = (p[2], p[3]) if elf64 else (p[1], p[2])
        if offset % 16384 != vaddr % 16384:
            raise ValueError(f"Invalid 16 KB ELF mapping: {name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native-dir", type=pathlib.Path, default=ROOT / ".native-build/jni")
    parser.add_argument("--template", type=pathlib.Path, default=ROOT / "releases/mobile-ffmpeg.aar")
    parser.add_argument("--output", type=pathlib.Path, default=ROOT / ".native-build/mobile-ffmpeg.aar")
    args = parser.parse_args()
    if args.template.resolve() == args.output.resolve():
        raise ValueError("The output must not overwrite the input template")
    native = {}
    for abi in ABIS:
        for lib in LIBRARIES:
            path = pathlib.Path(abi) / lib
            name = f"jni/{path.as_posix()}"
            data = (args.native_dir / path).read_bytes()
            verify_elf(data, name)
            native[name] = data
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.template) as original, zipfile.ZipFile(args.output, "w", zipfile.ZIP_DEFLATED) as out:
        for item in original.infolist():
            if item.filename.startswith("jni/") and item.filename.endswith(".so"):
                continue
            data = original.read(item)
            if item.filename == "AndroidManifest.xml":
                data = re.sub(rb'android:minSdkVersion="[0-9]+"', b'android:minSdkVersion="21"', data)
                data = re.sub(rb'android:versionName="[^"]+"', b'android:versionName="1.0.0"', data)
            out.writestr(item, data)
        for name, data in sorted(native.items()):
            out.writestr(name, data)
    print(f"Created {args.output}: {len(native)} native libraries verified at 16 KB")


if __name__ == "__main__":
    main()
