# PICO 4 Power Mode (разблокировка + тюнинг планировщика) v1.2

**LSPosed-модуль (1.2, versionCode 3)** для **PICO 4 (A8110)**: открывает скрытый
**режим производительности** в «Настройки → Лаборатория → Управление питанием»,
плюс **Magisk-компаньон**, применяющий высокопроизводительное планирование CPU/GPU
при активном режиме производительности.

> 中文: [README.md](README.md) · English: [README.en-US.md](README.en-US.md)

## Возможности

**LSPosed-модуль (APK)**
- Добавляет пункт **«Режим производительности»** в список управления питанием
  (в стоке только «Экономия» и «Стандарт»); текст локализован на все языки PICO 4.
- Выбор режима (`powerlevel=2`) вызывает официальный переключатель
  (`DeviceSwitchUtilsKt.e()`) и принудительно устанавливает:
  - **eyebuffer → 2448×2448**
  - «Стандарт»/«Экономия» (0/1) → **1504×1504** (стоковое значение, экономия)
- Согласование с **V-Sleep** по протоколу `pico_power_coord_v2`
  (last-writer-wins — без конфликтов и двойных записей).
- Проверка powerlevel + eyebuffer до фиксации; при ошибке — откат отображения.

**Magisk-компаньон (Tuner, `pico4-power-mode_tuner_magisk_v1.2.zip`)**
- Пока активен режим производительности (по сигналу eyebuffer=2448):
  - CPU governor → `performance` (все ядра)
  - GPU governor → `performance`
  - задержки планировщика ядра 5мс / min-granularity 1мс
  - nice для `pvrtrackingservice` и его потоков → `-10`
- В остальных режимах → стоковое планирование (`schedutil` / `msm-adreno-tz` / 10мс / 3мс / nice 0).
- Автоматически применяется при каждой загрузке; удаляется чисто.
- **Перенесено из режимов Performance/EXTREME проекта pico4-trackerlimit**
  (IO-планировщик не перенесён — ядро поддерживает только noop/cfq).

## Требования

- PICO 4 (A8110), root
- Magisk + **Zygisk**; **Zygisk Vector** (LSPosed-совместимый фреймворк)
- Tuner требует только Magisk (работает от root, без su-запросов)

## Установка

1. Установите `pico4-power-mode_lsposed_v1.2.apk`
2. Включите и задайте scope в Vector:

   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```

3. (Рекомендуется) Прошейте `pico4-power-mode_tuner_magisk_v1.2.zip` в Magisk
4. Перезагрузите шлем; откройте «Настройки → Лаборатория → Управление питанием».

## Сборка

- APK: `build.bat` (JDK `--release 8`, `r8.jar`, `apktool.jar`, `platform.keystore`) → `app/build/picolab-power.apk`
- Tuner: `python build_magisk.py` → `build/pico4-power-mode_tuner_magisk_v1.2.zip`

## Как это работает (APK)

Хук `com.picovr.fragments.PicolabFragment` в `com.picovr.settings`:

1. `T0(View)` — отметка открытия меню питания.
2. `PopupMenuHelper.c(...)` — добавляет третий пункт «Режим производительности».
3. `U0(int)` — публикует запрос `2|token|power|<0|1|2>`; после завершения транзакции
   V-Sleep (точный ack) вызывает `DeviceSwitchUtilsKt.e()` и принудительно задаёт
   eyebuffer (2→2448, иначе→1504); фиксирует `effective_owner/phase/ack`.
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
├── magisk/                   # Magisk-компаньон (новое в v1.2)
├── build.bat                 # сборка APK
├── build_magisk.py           # сборка Tuner
└── README*.md / COORDINATION.md
```

## Связанные проекты

- [pico4-trackerlimit](https://github.com/hhhbwc/pico4-trackerlimit) — разблокировка Motion Tracker 2.0.5
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit)

## Лицензия

MIT
