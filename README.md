# Kiro Mobile FFmpeg

A maintained, compact Android FFmpeg library for kiroJ2ME, based on MobileFFmpeg `v4.3.2-compact`.

The project preserves the existing MobileFFmpeg Java API (`com.arthenica.mobileffmpeg`) while preparing the native binaries for modern Android devices.

## Project status

| Item | Status |
| --- | --- |
| Base version | `v4.3.2-compact` |
| Android AAR | Included in `releases/` |
| 16 KB memory page size | Planned; the current native binaries are 4 KB-aligned |
| New Maven/JitPack release | Not yet published |

## Features

- FFmpeg and FFprobe APIs for media processing and metadata inspection.
- Compact Android package for audio and video conversion.
- Native libraries for `arm64-v8a`, `armeabi-v7a`, `x86`, and `x86_64`.
- Compatible with existing MobileFFmpeg Java imports.

## Use in an Android project

The existing AAR is available at [`releases/mobile-ffmpeg.aar`](releases/mobile-ffmpeg.aar). Copy it into your app module's `libs` directory and add the dependency to `app/build.gradle`:

```groovy
dependencies {
    implementation files('libs/mobile-ffmpeg.aar')
}
```

Example:

```java
import com.arthenica.mobileffmpeg.Config;
import com.arthenica.mobileffmpeg.FFmpeg;

int result = FFmpeg.execute(new String[]{"-i", inputPath, "-vn", outputPath});
if (result == Config.RETURN_CODE_SUCCESS) {
    // Conversion completed successfully.
}
```

> The bundled AAR is the legacy build. Do not use it as a 16 KB-compatible release.

## Source and build

| Directory | Purpose |
| --- | --- |
| [`android/`](android/) | Android Java wrapper, JNI bridge and Gradle project |
| [`src/`](src/) | FFmpeg and bundled external library source code |
| [`build/`](build/) | Native cross-compilation scripts |
| [`releases/`](releases/) | Prebuilt Android archive |
| [`docs/`](docs/) | Existing MobileFFmpeg documentation |

The original Android build entry point is `android.sh`. It requires a Unix-like shell, Android SDK, Android NDK and native build tools. See the [MobileFFmpeg Android build documentation](https://github.com/tanersener/mobile-ffmpeg/wiki/android.sh) for options. Modern NDK compatibility and 16 KB alignment are part of the planned update.

## Roadmap

- Modernize the Android native build configuration.
- Rebuild FFmpeg and JNI libraries with 16 KB ELF alignment.
- Verify the resulting AAR on supported Android architectures.
- Publish a compatible release for use in kiroJ2ME.

## Credits and license

Kiro Mobile FFmpeg is maintained by [kirozxy](https://github.com/kirozxy). It is derived from [MobileFFmpeg by Taner Sener](https://github.com/tanersener/mobile-ffmpeg), specifically the [compact distribution by Nikita Shakarun](https://github.com/nikita36078/mobile-ffmpeg/releases/tag/v4.3.2-compact), and includes FFmpeg and other open-source projects.

MobileFFmpeg is licensed under [LGPL v3.0](LICENSE.LGPLv3). Builds that enable optional GPL components are subject to [GPL v3.0](LICENSE.GPLv3). Included third-party components retain their individual licenses and copyright notices. See the [original licensing documentation](https://github.com/tanersener/mobile-ffmpeg/wiki/License) for details.

The source tree and existing copyright notices are retained; maintenance of this repository does not change ownership of the original code.
