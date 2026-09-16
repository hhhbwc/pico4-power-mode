# PICO 4 Power Mode (unlock + scheduling tuner) v1.2

An **LSPosed module (1.2, versionCode 3)** that unlocks the hidden **Performance Mode**
in **PICO 4 (A8110)** `Settings → Lab → Power Management`, plus a **Magisk companion**
that applies CPU/GPU performance scheduling while Performance Mode is active.

> 中文: [README.md](README.md) · Русский: [README.ru-RU.md](README.ru-RU.md)

## Features

**LSPosed module (APK)**
- Adds a **Performance Mode** entry to the Power Management dropdown
  (stock shows only Battery Saver / Standard); label localized to all PICO 4 languages.
- Selecting Performance Mode (`powerlevel=2`) invokes the official switch
  (`DeviceSwitchUtilsKt.e()`) and enforces:
  - **eyebuffer resolution → 2448×2448**
  - Standard / Battery Saver (0/1) → **1504×1504** (stock default, power saving)
- Coordinates with **V-Sleep** via the `pico_power_coord_v2` protocol
  (last-writer-wins — no conflicts, no double writes during sleep transactions).
- Verifies powerlevel + eyebuffer before committing; rolls back the UI on failure.

**Magisk companion (Tuner, `pico4-power-mode_tuner_magisk_v1.2.zip`)**
- While Performance Mode is active (follows the module's eyebuffer=2448 signal):
  - CPU governor → `performance` (all cores)
  - GPU governor → `performance`
  - kernel scheduler latency 5ms / min-granularity 1ms
  - `pvrtrackingservice` + threads nice → `-10`
- Otherwise → stock scheduling (`schedutil` / `msm-adreno-tz` / 10ms / 3ms / nice 0).
- Re-applied automatically on every boot; removed cleanly on uninstall.
- **Migrated from the pico4-trackerlimit Performance/EXTREME flavors**
  (IO scheduler not migrated — kernel only offers noop/cfq; no-effect props not migrated).

## Requirements

- PICO 4 (A8110), rooted
- Magisk + **Zygisk**; **Zygisk Vector** (LSPosed-compatible framework)
- Tuner needs Magisk only (runs as root, no su prompts)

## Installation

1. Install `pico4-power-mode_lsposed_v1.2.apk`
2. Enable + set scope in Vector:

   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```

3. (Recommended) Flash `pico4-power-mode_tuner_magisk_v1.2.zip` in Magisk
4. Reboot; open `Settings → Lab → Power Management` and select Performance Mode.

## Build

- APK: `build.bat` (JDK `--release 8`, `r8.jar`, `apktool.jar`, `platform.keystore`) → `app/build/picolab-power.apk`
- Tuner: `python build_magisk.py` → `build/pico4-power-mode_tuner_magisk_v1.2.zip`

## How it works (APK)

Hooks `com.picovr.fragments.PicolabFragment` in `com.picovr.settings`:

1. `T0(View)` — marks the power menu as opening.
2. `PopupMenuHelper.c(...)` — injects the third "Performance Mode" item (localized).
3. `U0(int)` — publishes a `2|token|power|<0|1|2>` request; waits for V-Sleep
   transaction cleanup (exact ack), then calls `DeviceSwitchUtilsKt.e()` and enforces
   eyebuffer (2→2448, else→1504); commits `effective_owner/phase/ack` and updates UI.
4. `Q(int)` — shows "Performance Mode" text for the button/current mode.

### Gotchas

- Resource strings are proguard-obfuscated — do not reflect `R.string`; set text via `MenuItemData.l(...)`.
- `xposed_init` must not contain a UTF-8 BOM.
- The runtime source of eyebuffer is `persist.pvr.config.eyebuffer_width/height`.
- The settings app cannot write CPU sysfs (root-only kernel perms), hence the root companion.

## Layout

```
pico4-power-mode/
├── app/                      # LSPosed module project
├── magisk/                   # Magisk companion tuner (new in v1.2)
├── build.bat                 # APK build
├── build_magisk.py           # Tuner build
└── README*.md / COORDINATION.md
```

## Related

- [pico4-trackerlimit](https://github.com/hhhbwc/pico4-trackerlimit) — Motion Tracker 2.0.5 unlock (single build since v2.7; scheduling moved here)
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit)

## License

MIT
