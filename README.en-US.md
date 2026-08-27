# PICO 4 High Performance Power Unlock

An **LSPosed module** that unlocks the hidden **Performance** and **Quality** options in **PICO 4 (A8110)** `Settings → Lab → Power Management`.

> 中文: [README.md](README.md) · Русский: [README.ru-RU.md](README.ru-RU.md)

## Features

- Adds **Performance** and **Quality** options to the `Settings → Lab → Power Management` dropdown (stock only shows Battery Saver / Standard).
- Selecting Performance (powerlevel=2) or Quality (powerlevel=3) invokes the system's official switch logic:
  - **Quality (3) forced to 2448×2448 eyebuffer** (full quality, sharper)
  - **Performance (2) uses stock 1504×1504 eyebuffer**
  - **stencil mesh off**
  - `target_fps=-1` (uncapped frame rate)
- **Bidirectional eyebuffer enforcement**:
  - Quality (3) → **2448×2448**
  - Performance (2) / Standard / Battery Saver (0/1) → **1504×1504**
- **FFR is only explicitly disabled in Performance** (`persist.pvr.config.ffr`):
  - Performance (2) → **off** (`0` — no edge blur, all GPU headroom goes to frame rate)
  - Quality (3) / Standard / Battery Saver (0/1) → FFR is left untouched so the system keeps its current value
- Dropdown item and button text show Performance or Quality.

## Requirements

- PICO 4 (A8110), rooted
- Magisk + **Zygisk** (stock Zygisk verified working; Zygisk-Next did not work on this unit)
- **Zygisk Vector** (LSPosed-compatible framework, `zygisk_vector` module)

## Installation

1. Build the module (see Build) or use `picolab-power.apk` from a release.
2. Install: `adb install -r app/build/picolab-power.apk`
3. Configure scope (via Vector cli, or add in the Vector manager):

   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```

4. Restart the settings app (`pkill -f com.picovr.settings`), open `Settings → Lab → Power Management`, and select your desired mode.

## Build

Standard LSPosed module project. Depends on JDK (`--release 8`), `r8.jar` (D8), `apktool.jar`, `platform.keystore`.

```
build.bat
```

Output: `app/build/picolab-power.apk`

- javac must use `--release 8` (JDK 26 emits class v52, rejected by D8).
- Xposed API uses hand-written stubs (`app/stub/`), compile-only, not packaged into dex.
- apktool package + jarsigner self-sign (no native lib, no zipalign needed).

## How it works

Hooks `com.picovr.fragments.PicolabFragment` in `com.picovr.settings`:

1. **`T0(View)`** — sets a flag indicating the power menu is opening.
2. **`PopupMenuHelper.c(...)`** — reflects into the power menu's `List<MenuItemData>` and appends "性能" and "画质" items.
3. **`U0(int)`** — intercepts all levels (0/1/2/3): calls `DeviceSwitchUtilsKt.e(context, i)` (system switch), **then explicitly enforces eyebuffer and FFR**: Quality (3)→2448×2448, all other levels→1504×1504; Performance (2)→FFR off, all other levels→FFR on.
4. **`Q(int)`** — makes the button text show the correct mode name.

### Gotchas

- `picolab_powerFunc3` resource string is proguard-obfuscated at runtime; **do not reflect into R.string** (`NoSuchFieldError`). Instead set text via `MenuItemData.l("性能")` or hardcode the resource ID.
- `xposed_init` must **not have a UTF-8 BOM** (otherwise the class name's first byte is corrupted → `ClassNotFoundException`).
- `T0` is a private method taking a `View` (not parameterless).
- The real source of eyebuffer resolution at runtime is the **`persist.pvr.config.eyebuffer_width/height`** system properties (not `PXRuleValueFile.txt`), so this module directly writes `setSystemProperties` for 2448/1504 on switch.

## Layout

```
pico4-power-mode/
├── app/                      # LSPosed module project
│   ├── AndroidManifest.xml
│   ├── apktool.yml
│   ├── assets/xposed_init    # entry class declaration
│   ├── res/values/arrays.xml # xposedscope
│   ├── src/com/peaklab/powermode/PowerModeHook.java  # entry hook
│   └── stub/                 # compile-only Xposed/Android stubs
├── build.bat                 # build script
└── README.md / README.en-US.md / README.ru-RU.md
```

## Related

- [pico4-paper_tracker-autostart](https://github.com/hhhbwc/pico4-paper_tracker-autostart)
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit)

## License

MIT
