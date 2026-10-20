# Pico 4 Power Mode v1.4 (Tuner) / v1.3 (APK)

🇬🇧 English below · 🇷🇺 Русский ниже · 🇨🇳 中文在最下方

---

## 🇬🇧 English

**Highlights**

- **Pico3dResolution relay is now executed, not just deferred to.** The tuner
  applies `max:min:cpu:gpu:latency` from `/data/local/tmp/res3d_pwr.relay`
  directly, so a frozen res3d process no longer breaks performance mode or
  stock restore. It wakes res3d with
  `content query --uri content://com.hamer.res3d.guardian`.
- **Performance Mode relay takeover.** The tuner saves your relay, writes
  `0:6:1:1:1`, applies it, and restores the saved relay when the mode ends.
- **120 Hz arbitration.** With `persist.pvr.display.type=jdi493120`, the tuner
  pins `persist.pvr.config.eyebuffer_width/height` to `2160` unless V-Sleep owns
  them. APK 1.3 now also writes 2160 at 120 Hz.
- **No more stock-restore gap.** Res3D's GuardianService only implements the
  mode=1 branch; the tuner restores `schedutil` / `msm-adreno-tz` for mode=2.

**Install**

1. Flash `pico4-power-mode_tuner_magisk_v1.4.zip` in Magisk.
2. Reboot. The tuner starts from `service.sh` and re-applies on every boot.
3. APK 1.3 includes the 120 Hz fix; the 120 Hz guard is also in the tuner.

**Versions**: APK 1.3 (versionCode 4) · Tuner v1.4.

---

## 🇷🇺 Русский

**Главное**

- **Relay Pico3dResolution теперь исполняется, а не просто игнорируется.**
  Тюнер сам применяет `max:min:cpu:gpu:latency` из
  `/data/local/tmp/res3d_pwr.relay`, поэтому замороженный res3d больше не ломает
  режим производительности и возврат в сток. Процесс будится через
  `content query --uri content://com.hamer.res3d.guardian`.
- **Захват relay в режиме производительности.** Тюнер сохраняет ваш relay,
  пишет `0:6:1:1:1`, применяет его и восстанавливает сохранённое при выходе.
- **Арбитраж 120 Гц.** При `persist.pvr.display.type=jdi493120` тюнер удерживает
  `persist.pvr.config.eyebuffer_width/height` на `2160`, кроме случаев V-Sleep.
  Исходники APK 1.3 также пишут 2160 при 120 Гц.
- **Возврат stock больше не теряется.** GuardianService Res3D реализует только
  ветку mode=1; тюнер восстанавливает `schedutil` / `msm-adreno-tz` для mode=2.

**Установка**

1. Прошейте `pico4-power-mode_tuner_magisk_v1.4.zip` в Magisk.
2. Перезагрузите. Тюнер запускается из `service.sh` и применяется при каждой загрузке.
3. APK 1.3 содержит фикс 120 Гц; защита 120 Гц также реализована в тюнере.

**Версии**: APK 1.3 (versionCode 4) · Tuner v1.4.

---

## 🇨🇳 中文

**本次更新**

- **Res3D relay 从“让位”改为“执行”**：Tuner 直接执行
  `/data/local/tmp/res3d_pwr.relay` 里的 `max:min:cpu:gpu:latency`，
  Res3D 进程被冻结也不会再导致性能模式失效或无法恢复 stock；
  需要时用 `content query --uri content://com.hamer.res3d.guardian` 唤醒。
- **性能模式接管 relay**：保存你的 relay → 写入 `0:6:1:1:1` → 执行 →
  退出时恢复。
- **120Hz 仲裁**：`persist.pvr.display.type=jdi493120` 时，Tuner 把
  `persist.pvr.config.eyebuffer_width/height` 钉在 `2160`，V-Sleep 期间让位；
  APK 1.3 也已改为 120Hz 下写 2160。
- **补齐 stock 恢复**：Res3D 的 GuardianService 只实现 mode=1，不会恢复
  `schedutil` / `msm-adreno-tz`；mode=2 的恢复由 Tuner 完成。

**安装**

1. Magisk 刷入 `pico4-power-mode_tuner_magisk_v1.4.zip`。
2. 重启；Tuner 由 `service.sh` 启动，每次开机自动应用。
3. APK 1.3 已包含 120Hz 修复；120Hz 保护同时也在 Tuner 里。

**版本**：APK 1.3（versionCode 4）· Tuner v1.4。
