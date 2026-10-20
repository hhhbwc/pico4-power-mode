# PICO 4 Power Mode (разблокировка + тюнинг планировщика)

**LSPosed-модуль (APK 1.3, versionCode 4)** для **PICO 4 (A8110)**: открывает скрытый
**режим производительности** в «Настройки → Лаборатория → Управление питанием»,
плюс **Magisk-компаньон (Tuner v1.4)**, применяющий высокопроизводительное
планирование CPU/GPU при активном режиме производительности.

> 中文: [README.md](README.md) · English: [README.en-US.md](README.en-US.md)

## Обновления v1.4 (Tuner)

- **Согласование с Pico3dResolution:** если установлен `com.hamer.res3d`, его
  `/data/local/tmp/res3d_pwr.relay` — источник истины. Тюнер сам применяет relay
  (governor, pwrlevel, планировщик) и будит res3d через
  `content query --uri content://com.hamer.res3d.guardian`, если PICO его заморозил.
- **Режим производительности:** сохранить ваш relay → записать `0:6:1:1:1` →
  применить → восстановить при выходе. Res3D сам реализует только ветку mode=1
  и не возвращает stock — это делает тюнер.
- **Арбитраж 120 Гц:** при `persist.pvr.display.type=jdi493120` удерживать
  `persist.pvr.config.eyebuffer_width/height` на 2160, кроме случаев V-Sleep.
- **APK 1.3:** `PowerModeHook` теперь пишет 2160 и при 120 Гц. Старый APK 1.2
  всё ещё пишет 2448/1504; Tuner v1.4 исправляет это за 2 с.

> APK 1.3 и Tuner v1.4 собраны и проверены на устройстве (обновление / удаление / переустановка).

## Возможности

**LSPosed-модуль (APK)**
- Добавляет пункт **«Режим производительности»** в список управления питанием
  (в стоке только «Экономия» и «Стандарт»); текст локализован на все языки PICO 4.
- Выбор режима (`powerlevel=2`) вызывает официальный переключатель
  (`DeviceSwitchUtilsKt.e()`) и принудительно устанавливает:
  - **eyebuffer → 2448×2448** (2160×2160 при 120 Гц)
  - «Стандарт»/«Экономия» (0/1) → **1504×1504** (стоковое значение; 2160×2160 при 120 Гц)
- Согласование с **V-Sleep** по протоколу `pico_power_coord_v2`
  (last-writer-wins — без конфликтов и двойных записей).
- Проверка powerlevel + eyebuffer до фиксации; при ошибке — откат отображения.

**Magisk-компаньон (Tuner v1.4, `pico4-power-mode_tuner_magisk_v1.4.zip`)**
- **Если установлен Pico3dResolution:** relay — источник истины. Тюнер применяет
  его поля CPU/GPU/latency и зеркалит nice трекинг-сервиса; будит res3d, если
  процесс заморожен.
- **Режим производительности:** сохраняет relay, пишет `0:6:1:1:1`, применяет его
  и восстанавливает сохранённый relay при выходе. Без res3d тюнинг применяется
  напрямую по `powerlevel=2` / `perf_active=1` / legacy eyebuffer=2448.
- Тюнинг: CPU governor → `performance` (все ядра), GPU governor → `performance`,
  задержки планировщика 5мс/1мс, nice `pvrtrackingservice` → `-10`.
- В остальных режимах → стоковое планирование (`schedutil` / `msm-adreno-tz` / 10мс / 3мс / nice 0).
- **120 Гц:** eyebuffer удерживается на 2160; уступает при активном/восстанавливающемся V-Sleep.
- Автоматически применяется при каждой загрузке; удаление восстанавливает relay и сток.
- **Перенесено из режимов Performance/EXTREME проекта pico4-trackerlimit**
  (IO-планировщик не перенесён — ядро поддерживает только noop/cfq).

## Требования

- PICO 4 (A8110), root
- Magisk + **Zygisk**; **Zygisk Vector** (LSPosed-совместимый фреймворк)
- Tuner требует только Magisk (работает от root, без su-запросов)

## Установка

1. Установите `pico4-power-mode_lsposed_v1.3.apk`
2. Включите и задайте scope в Vector:

   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```

3. (Рекомендуется) Прошейте `pico4-power-mode_tuner_magisk_v1.4.zip` в Magisk
4. Перезагрузите шлем; откройте «Настройки → Лаборатория → Управление питанием».

## Сборка

- APK: `build.bat` (JDK `--release 8`, `r8.jar`, `apktool.jar`, `platform.keystore`) → `app/build/picolab-power.apk`
- Tuner: `python build_magisk.py` → `build/pico4-power-mode_tuner_magisk_v1.4.zip`

## Как это работает (APK)

Хук `com.picovr.fragments.PicolabFragment` в `com.picovr.settings`:

1. `T0(View)` — отметка открытия меню питания.
2. `PopupMenuHelper.c(...)` — добавляет третий пункт «Режим производительности».
3. `U0(int)` — публикует запрос `2|token|power|<0|1|2>`; после завершения транзакции
   V-Sleep (точный ack) вызывает `DeviceSwitchUtilsKt.e()` и принудительно задаёт
   eyebuffer (2→2448, иначе→1504; при 120 Гц оба → 2160); фиксирует `effective_owner/phase/ack`.
4. `Q(int)` — текст кнопки/текущего режима.

### Нюансы

- Строки ресурсов обфусцированы proguard — не читать `R.string` рефлексией.
- `xposed_init` без UTF-8 BOM.
- Источник eyebuffer в рантайме — свойства `persist.pvr.config.eyebuffer_width/height`.
- Приложение настроек не может писать в sysfs CPU (права только у root) — поэтому тюнинг в Magisk-компаньоне.

## Структура

```
pico4-power-mode/
├── app/                      # проект LSPosed-модуля
├── magisk/                   # Magisk-компаньон (v1.4)
├── build.bat                 # сборка APK
├── build_magisk.py           # сборка Tuner
└── README*.md / COORDINATION.md
```

## Связанные проекты

- [pico4-trackerlimit](https://github.com/hhhbwc/pico4-trackerlimit) — разблокировка Motion Tracker 2.0.5
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit)

## Лицензия

MIT
