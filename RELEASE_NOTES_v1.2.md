# Pico 4 Power Mode v1.2

🇬🇧 English below · 🇷🇺 Русский ниже · 🇨🇳 中文在最下方

---

## 🇬🇧 English

**Highlights**

- **CPU/GPU performance tuning merged in.** New Magisk companion `pico4-power-mode_tuner_magisk_v1.2.zip`:
  while Performance Mode is active it applies CPU/GPU governor `performance`,
  kernel scheduler latencies 5ms/1ms and `-10` nice for the tracking service;
  otherwise it restores stock scheduling. *(Migrated from the pico4-trackerlimit
  Performance/EXTREME flavors, now discontinued there in favor of this tuner.)*
- **V-Sleep coordination** — last-writer-wins `pico_power_coord_v2` endpoint;
  no more conflicts or double writes between the modules.
- **Bidirectional eyebuffer enforcement** — Performance → 2448×2448;
  Standard/Battery Saver → 1504×1504.
- **Localized** "Performance Mode" label for all PICO 4 Settings languages.

**Install**

1. Install `pico4-power-mode_lsposed_v1.2.apk`; enable in Vector + scope `com.picovr.settings`.
   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```
2. Flash `pico4-power-mode_tuner_magisk_v1.2.zip` in Magisk (optional but recommended — enables the CPU/GPU tuning).
3. Reboot → `Settings → Lab → Power Management → Performance Mode`.

**Requirements**: PICO 4 A8110, root, Magisk (+Zygisk), Zygisk Vector.

**Versions**: APK 1.2 (versionCode 3) · Tuner v1.2.

---

## 🇷🇺 Русский

**Главное**

- **Тюнинг CPU/GPU добавлен.** Новый Magisk-компаньон `pico4-power-mode_tuner_magisk_v1.2.zip`:
  при активном режиме производительности включает CPU/GPU governor `performance`,
  задержки планировщика 5мс/1мс и nice `-10` для трекинг-сервиса; иначе возвращает сток.
  *(Перенесено из режимов Performance/EXTREME проекта pico4-trackerlimit.)*
- **Согласование с V-Sleep** — протокол last-writer-wins `pico_power_coord_v2`.
- **Двунаправленный eyebuffer** — производительность → 2448×2448; стандарт/экономия → 1504×1504.
- **Локализация** пункта «Режим производительности» на все языки PICO 4.

**Установка**

1. Установите `pico4-power-mode_lsposed_v1.2.apk`; включите в Vector + scope `com.picovr.settings`.
2. Прошейте `pico4-power-mode_tuner_magisk_v1.2.zip` в Magisk (рекомендуется — включает тюнинг CPU/GPU).
3. Перезагрузка → «Настройки → Лаборатория → Управление питанием → Режим производительности».

**Требования**: PICO 4 A8110, root, Magisk (+Zygisk), Zygisk Vector.

**Версии**: APK 1.2 (versionCode 3) · Tuner v1.2.

---

## 🇨🇳 中文

**本次更新**

- **合并 CPU/GPU 性能调优**：新增 Magisk 伴生模块 `pico4-power-mode_tuner_magisk_v1.2.zip`——
  性能模式生效时应用 CPU/GPU 调度器 `performance`、内核调度延迟 5ms/1ms、
  追踪服务 nice `-10`；其他档位恢复原厂调度。（由 pico4-trackerlimit 性能/极限档迁移而来）
- **V-Sleep 协调**：`pico_power_coord_v2` last-writer-wins 协议，模块间不再打架。
- **双向 eyebuffer**：性能模式 → 2448×2448；标准/续航 → 1504×1504。
- 「性能模式」文案全语言本地化。

**安装**

1. 安装 `pico4-power-mode_lsposed_v1.2.apk`，在 Vector 启用并配置 scope（`com.picovr.settings`）。
2. Magisk 刷入 `pico4-power-mode_tuner_magisk_v1.2.zip`（推荐，启用 CPU/GPU 调优）。
3. 重启 → 「设置 → 实验室 → 电源管理方案 → 性能模式」。

**要求**：PICO 4 A8110 / root / Magisk (+Zygisk) / Zygisk Vector。

**版本**：APK 1.2（versionCode 3）· Tuner v1.2。

## Checksums / Контрольные суммы / 校验值

| File | MD5 | SHA-256 |
|---|---|---|
| pico4-power-mode_lsposed_v1.2.apk | `b7805959ba09064f0573858a986ad9b3` | `526bd0aebd3c6b0cecc2348615af58eefe3d6adf8eede3ed9763f6d014d2625e` |
| pico4-power-mode_tuner_magisk_v1.2.zip | `c24cd6d8ea31405abb6afd85464850e8` | `728c610bfd89f41378c174d9704500f75409fac99e5c3c1c22ad1e6632df5a26` |
