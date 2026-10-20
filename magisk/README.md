# PICO 4 Power Mode Tuner — Magisk companion for pico4-power-mode

> **v1.4 arbitration:** at 120 Hz (`persist.pvr.display.type=jdi493120`) the
> eyebuffer is pinned to 2160×2160 unless V-Sleep owns it. When Pico3dResolution
> is installed, its relay remains the source of truth; this tuner applies the
> relay directly (and wakes the frozen res3d process), so performance mode and
> stock restore work even when res3d is not running.

Applies CPU/GPU performance scheduling while **Performance Mode** is active,
and restores stock scheduling otherwise.

> 🇬🇧 English · 🇷🇺 Русский · 🇨🇳 中文 (внизу / 最下方)

## English

- **Companion** for the `pico4-power-mode` LSPosed module (install that APK too).
- **v1.4 ownership protocol**
  1. If `com.hamer.res3d` is installed and `/data/local/tmp/res3d_pwr.relay`
     exists, that relay is the source of truth. The tuner applies its
     `max:min:cpu:gpu:latency` fields directly (governors, pwrlevels, scheduler),
     mirrors tracking nice, and wakes the process with
     `content query --uri content://com.hamer.res3d.guardian` when PICO's
     freezer has parked it.
  2. While Performance Mode is active, the tuner saves your relay, writes
     `0:6:1:1:1`, applies it, and restores the saved relay when the mode ends.
  3. Without res3d, Performance Mode (`powerlevel=2`, `perf_active=1`, or the
     legacy eyebuffer `2448` signal) is applied here directly; otherwise stock.
- **120 Hz:** pins `persist.pvr.config.eyebuffer_width/height` to `2160` unless
  V-Sleep is active or restoring.
- Runs as root via Magisk (no su prompts). Re-applies automatically each boot.
- Install: flash in Magisk → reboot. Uninstall: remove in Magisk → reboot
  (restores the saved relay and stock scheduling).
- Requires root (Magisk) + the `pico4-power-mode` module.
- For learning & research only.

## Русский

- **Компаньон** для LSPosed-модуля `pico4-power-mode` (APK тоже нужен).
- **Протокол владения v1.4**
  1. Если установлен `com.hamer.res3d` и существует
     `/data/local/tmp/res3d_pwr.relay`, relay — источник истины. Тюнер сам
     применяет его поля `max:min:cpu:gpu:latency` (governor, pwrlevel,
     планировщик), зеркалит nice трекинг-сервиса и будит процесс через
     `content query --uri content://com.hamer.res3d.guardian`, если PICO его
     заморозил.
  2. При активном режиме производительности тюнер сохраняет ваш relay, пишет
     `0:6:1:1:1`, применяет его и восстанавливает сохранённый relay при выходе.
  3. Без res3d режим производительности (`powerlevel=2`, `perf_active=1` или
     legacy-сигнал eyebuffer `2448`) применяется напрямую; иначе — сток.
- **120 Гц:** удерживает `persist.pvr.config.eyebuffer_width/height` на `2160`,
  кроме случаев, когда владеет V-Sleep.
- Работает через root (Magisk), без su-запросов. Автоприменение после загрузки.
- Установка: прошить в Magisk → перезагрузка. Удаление: удалить модуль →
  перезагрузка (восстанавливает relay и стоковый планировщик).
- Только для обучения и исследований.

## 中文

- `pico4-power-mode`（LSPosed 模块）的**伴生调优组件**（需同时安装其 APK）。
- **v1.4 所有权协议**
  1. 装了 `com.hamer.res3d` 且存在 `/data/local/tmp/res3d_pwr.relay` 时，
     **relay 是唯一事实来源**。Tuner 直接执行它的
     `max:min:cpu:gpu:latency`（governor、pwrlevel、调度延迟），同步追踪服务
     nice；Res3D 被 PICO 冻结时用
     `content query --uri content://com.hamer.res3d.guardian` 唤醒。
  2. 性能模式生效期间，Tuner 先保存你的 relay，写入 `0:6:1:1:1` 并执行，
     退出时恢复保存的 relay。
  3. 没装 Res3D 时，按 `powerlevel=2` / `perf_active=1` / 旧版 eyebuffer
     `2448` 信号直接调优；否则恢复 stock。
- **120Hz**：把 `persist.pvr.config.eyebuffer_width/height` 钉在 `2160`，
  V-Sleep 生效或恢复期间让位。
- 经 Magisk 以 root 运行（无 su 弹窗），每次开机自动恢复应用；卸载即还原
  relay 和原厂调度。
- 用途：把原 trackerlimit 性能档的 CPU 调度调优迁移到 power-mode 体系。
- 仅供学习研究。
