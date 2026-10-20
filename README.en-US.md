# PICO 4 Power Mode (unlock + scheduling tuner)

An **LSPosed module (APK 1.2, versionCode 3)** that unlocks the hidden **Performance Mode**
in **PICO 4 (A8110)** `Settings → Lab → Power Management`, plus a **Magisk companion
(Tuner v1.4)** that applies CPU/GPU performance scheduling while Performance Mode is active.

> 中文: [README.md](README.md) · Русский: [README.ru-RU.md](README.ru-RU.md)

## v1.4 updates (Tuner)

- **Pico3dResolution coordination:** when `com.hamer.res3d` is installed, its
  `/data/local/tmp/res3d_pwr.relay` is the source of truth. The tuner applies
  the relay directly (governors, pwrlevels, scheduler) and wakes res3d with
  `content query --uri content://com.hamer.res3d.guardian` when PICO's freezer
  has parked it.
- **Performance Mode takeover:** save your relay → write `0:6:1:1:1` → apply →
  restore on exit. Res3D itself only implements the mode=1 branch and never
  restores stock, so that restore is done here.
- **120 Hz arbitration:** at `persist.pvr.display.type=jdi493120`, pin
  `persist.pvr.config.eyebuffer_width/height` to 2160 unless V-Sleep owns it.
- **APK source:** `PowerModeHook` now also writes 2160 at 120 Hz. The released
  APK 1.2 still writes 2448/1504; Tuner v1.4 corrects it within 2 s. A rebuilt
  APK gets the behavior natively.

## Features

**LSPosed module (APK)**
- Adds a **Performance Mode** entry to the Power Management dropdown
  (stock shows only Battery Saver / Standard); label localized to all PICO 4 languages.
- Selecting Performance Mode (`powerlevel=2`) invokes the official switch
  (`DeviceSwitchUtilsKt.e()`) and enforces:
  - **eyebuffer resolution → 2448×2448** (2160×2160 at 120 Hz)
  - Standard / Battery Saver (0/1) → **1504×1504** (stock default, power saving; 2160×2160 at 120 Hz)
- Coordinates with **V-Sleep** via the `pico_power_coord_v2` protocol
  (last-writer-wins — no conflicts, no double writes during sleep transactions).
- Verifies powerlevel + eyebuffer before committing; rolls back the UI on failure.

**Magisk companion (Tuner v1.4, `pico4-power-mode_tuner_magisk_v1.4.zip`)**
- **With Pico3dResolution installed:** the relay is the source of truth. The tuner
  applies its CPU/GPU/latency fields and mirrors tracking nice; it wakes res3d
  when the process is frozen.
- **Performance Mode:** saves the relay, writes `0:6:1:1:1`, applies it, and
  restores the saved relay on exit. Without res3d it tunes directly on
  `powerlevel=2` / `perf_active=1` / the legacy eyebuffer=2448 signal.
- Tuning: CPU governor → `performance` (all cores), GPU governor → `performance`,
  kernel scheduler latency 5ms/1ms, `pvrtrackingservice` + threads nice → `-10`.
- Otherwise → stock scheduling (`schedutil` / `msm-adreno-tz` / 10ms / 3ms / nice 0).
- **120 Hz:** pins the eyebuffer to 2160; yields while V-Sleep is active/restoring.
- Re-applied automatically on every boot; uninstall restores the relay and stock scheduling.
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

3. (Recommended) Flash `pico4-power-mode_tuner_magisk_v1.4.zip` in Magisk
4. Reboot; open `Settings → Lab → Power Management` and select Performance Mode.

## Build

- APK: `build.bat` (JDK `--release 8`, `r8.jar`, `apktool.jar`, `platform.keystore`) → `app/build/picolab-power.apk`
- Tuner: `python build_magisk.py` → `build/pico4-power-mode_tuner_magisk_v1.4.zip`

## How it works (APK)

Hooks `com.picovr.fragments.PicolabFragment` in `com.picovr.settings`:

1. `T0(View)` — marks the power menu as opening.
2. `PopupMenuHelper.c(...)` — injects the third "Performance Mode" item (localized).
3. `U0(int)` — publishes a `2|token|power|<0|1|2>` request; waits for V-Sleep
   transaction cleanup (exact ack), then calls `DeviceSwitchUtilsKt.e()` and enforces
   eyebuffer (2→2448, else→1504; both 2160 at 120 Hz); commits `effective_owner/phase/ack` and updates UI.
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
├── magisk/                   # Magisk companion tuner (v1.4)
├── build.bat                 # APK build
├── build_magisk.py           # Tuner build
└── README*.md / COORDINATION.md
```

## Related

- [pico4-trackerlimit](https://github.com/hhhbwc/pico4-trackerlimit) — Motion Tracker 2.0.5 unlock (single build since v2.7; scheduling moved here)
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit)

## License

MIT
