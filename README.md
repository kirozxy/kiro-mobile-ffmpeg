# Kiro Mobile FFmpeg

A maintained, compact Android FFmpeg library for kiroJ2ME, based on MobileFFmpeg `v4.3.2-compact`.

The project preserves the existing MobileFFmpeg Java API (`com.arthenica.mobileffmpeg`) and rebuilds the compact native libraries with Android NDK r28 for 16 KB memory page sizes.

## Project status

| Item | Status |
| --- | --- |
| Base version | `v4.3.2-compact` |
| Android AAR | `v1.0.0` |
| Minimum Android API | 21 (Android 5.0) |
| 16 KB memory page size | All 40 native binaries across four ABIs verified for 16 KB ELF alignment |
| Maven/JitPack version | `v1.0.0` |

## Features

- FFmpeg and FFprobe APIs for media processing and metadata inspection.
- Compact Android package for converting IMA WAV and Yamaha MMF ADPCM audio to unsigned 8-bit PCM WAV.
- Native libraries for `arm64-v8a`, `armeabi-v7a`, `x86`, and `x86_64`.
- Compatible with existing MobileFFmpeg Java imports.

## Use in an Android project

Add JitPack to your project's `settings.gradle`:

```groovy
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
```

Add the dependency to your app module's `build.gradle`:

```groovy
dependencies {
    implementation 'com.github.kirozxy:kiro-mobile-ffmpeg:v1.0.0'
}
```

Example:

```java
import com.arthenica.mobileffmpeg.Config;
import com.arthenica.mobileffmpeg.FFmpeg;

int result = FFmpeg.execute(new String[]{"-i", inputPath, "-acodec", "pcm_u8", "-ar", "16000", outputPath});
if (result == Config.RETURN_CODE_SUCCESS) {
    // Conversion completed successfully.
}
```

The AAR contains the rebuilt native libraries and retains the original Java classes and API. The host app must also use a compatible Android Gradle Plugin and 16 KB-compatible native dependencies.

## Source and build

| Directory | Purpose |
| --- | --- |
| [`android/`](android/) | Android Java wrapper, JNI bridge and Gradle project |
| [`src/`](src/) | FFmpeg and bundled external library source code |
| [`build/`](build/) | Native cross-compilation scripts |
| [`releases/`](releases/) | Prebuilt Android archive |
| [`docs/`](docs/) | Existing MobileFFmpeg documentation |

### Rebuild the compact 16 KB AAR

Use Android NDK r28 or newer, Bash, GNU Make, Python 3, and standard Unix build utilities. This build path also works on Windows with Git Bash and an MSYS-compatible GNU Make on `PATH`.

```bash
export ANDROID_NDK_ROOT=/path/to/android-sdk/ndk/28.2.13676358
JOBS=8 bash build/android-compact-16kb.sh
python3 build/package-compact-16kb.py
```

The script builds the native libraries for all four ABIs, explicitly links with a 16 KB maximum and common page size, and keeps the compact codec configuration. The packaging script verifies the ELF load segments before producing `.native-build/mobile-ffmpeg.aar`. To build just one ABI, pass its name to the shell script. The existing `android.sh` is the original legacy build entry point; use the commands above for the compact build.

The Android CPU features compatibility source in `android/jni/cpufeatures/` comes from NDK r22, including its original notice, because it is no longer shipped by NDK r28.

## Credits and license

Kiro Mobile FFmpeg is maintained by [kirozxy](https://github.com/kirozxy). It is derived from [MobileFFmpeg by Taner Sener](https://github.com/tanersener/mobile-ffmpeg), specifically the [compact distribution by Nikita Shakarun](https://github.com/nikita36078/mobile-ffmpeg/releases/tag/v4.3.2-compact), and includes FFmpeg and other open-source projects.

MobileFFmpeg is licensed under [LGPL v3.0](LICENSE.LGPLv3). Builds that enable optional GPL components are subject to [GPL v3.0](LICENSE.GPLv3). Included third-party components retain their individual licenses and copyright notices. See the [original licensing documentation](https://github.com/tanersener/mobile-ffmpeg/wiki/License) for details.

The source tree and existing copyright notices are retained; maintenance of this repository does not change ownership of the original code.
