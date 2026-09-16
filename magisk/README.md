# PICO 4 Power Mode Tuner — Magisk companion for pico4-power-mode

Applies CPU/GPU performance scheduling while **Performance Mode** is active,
and restores stock scheduling otherwise.

> 🇬🇧 English · 🇷🇺 Русский · 🇨🇳 中文 (внизу / 最下方)

## English

- **Companion** for the `pico4-power-mode` LSPosed module (install that APK too).
- When Performance Mode is on (the module forces eyebuffer `2448`), the tuner applies:
  - CPU governor → `performance` (all cores)
  - GPU governor → `performance`
  - kernel scheduler latency 5ms / min-granularity 1ms
  - `pvrtrackingservice` + threads nice → `-10`
- Otherwise → stock scheduling (`schedutil` / `msm-adreno-tz` / 10ms / 3ms / nice 0).
- Runs as root via Magisk (no su prompts). Re-applies automatically each boot.
- Install: flash in Magisk → reboot. Uninstall: remove in Magisk → reboot (restores stock).
- Requires root (Magisk) + the `pico4-power-mode` module.
- For learning & research only.

## Русский

- **Компаньон** для LSPosed-модуля `pico4-power-mode` (APK тоже нужен).
- Когда включён режим производительности (eyebuffer `2448`): CPU governor → `performance`,
  GPU governor → `performance`, latency планировщика 5мс/1мс, nice трекинг-сервиса `-10`.
- Иначе — стоковый режим (`schedutil` / `msm-adreno-tz` / 10мс / 3мс / nice 0).
- Работает через root (Magisk), без su-запросов. Автоприменение после каждой загрузки.
- Установка: прошить в Magisk → перезагрузка. Удаление: удалить модуль → перезагрузка.
- Только для обучения и исследований.

## 中文

- `pico4-power-mode`（LSPosed 模块）的**伴生调优组件**（需同时安装其 APK）。
- 性能模式生效时（模块强制 eyebuffer=`2448`）应用：CPU 调度器→`performance`、
  GPU 调度器→`performance`、内核调度延迟 5ms/1ms、追踪服务及线程 nice→`-10`。
- 其他档位→恢复原厂调度（`schedutil`/`msm-adreno-tz`/10ms/3ms/nice 0）。
- 经 Magisk 以 root 运行（无 su 弹窗），每次开机自动恢复应用；卸载即还原。
- 用途：把原 trackerlimit 性能档的 CPU 调度调优迁移到 power-mode 体系。
- 仅供学习研究。
