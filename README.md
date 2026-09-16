# PICO 4 Power Mode（性能模式解锁 + 调度调优）v1.2

一个 **LSPosed 模块（1.2，versionCode 3）**，用于在 **PICO 4（A8110）** 的
「设置 → 实验室 → 电源管理方案」中解锁隐藏的 **性能模式** 档位；
并配套一个 **Magisk 伴生调优模块**，在性能模式生效时应用 CPU/GPU 高性能调度。

> English: [README.en-US.md](README.en-US.md) · Русский: [README.ru-RU.md](README.ru-RU.md)

## 功能

**LSPosed 模块（APK）**
- 在电源管理方案下拉框中新增 **性能模式** 档位（原厂仅「续航」「标准」），文案跟随系统语言本地化。
- 选择性能模式（`powerlevel=2`）即调用官方切换逻辑（`DeviceSwitchUtilsKt.e()`），并强制：
  - **eyebuffer 分辨率 → 2448×2448**（满画质档）
  - 标准/续航档（0/1）→ **1504×1504**（出厂默认，省电）
- 以 `pico_power_coord_v2` 协议与 **V-Sleep** 协调（last-writer-wins）：
  V-Sleep 事务期间不抢占、不重复写入，避免两个模块互相打架。
- 切换后校验 powerlevel 与 eyebuffer，成功才更新 UI；失败自动回滚显示。

**Magisk 伴生模块（Tuner，`pico4-power-mode_tuner_magisk_v1.2.zip`）**
- 性能模式生效时应用（跟随模块写入的 eyebuffer=2448 信号）：
  - CPU 调度器 → `performance`（全部核心）
  - GPU 调度器 → `performance`
  - 内核调度延迟 5ms / min-granularity 1ms
  - `pvrtrackingservice` 及其线程 nice → `-10`
- 其他档位 → 恢复原厂调度（`schedutil` / `msm-adreno-tz` / 10ms / 3ms / nice 0）。
- 每次开机自动重新应用；卸载即还原。**这套调优由原 trackerlimit 性能/极限档迁移而来**
  （IO 调度器因本内核仅支持 noop/cfq 未迁移；已验证无效果的属性未迁移）。

## 环境要求

- PICO 4（A8110），已 root
- Magisk + **Zygisk**；**Zygisk Vector**（LSPosed 兼容框架）
- Tuner 需要 Magisk（无 su 弹窗，模块内 root 执行）

## 安装

1. 安装 `pico4-power-mode_lsposed_v1.2.apk`
2. 在 Vector 中启用并配置 scope：

   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```

3. （推荐）在 Magisk 刷入 `pico4-power-mode_tuner_magisk_v1.2.zip`
4. 重启；打开「设置 → 实验室 → 电源管理方案」选择「性能模式」。

## 构建

- APK：`build.bat`（需 JDK `--release 8`、`r8.jar`、`apktool.jar`、`platform.keystore`）→ `app/build/picolab-power.apk`
- Tuner：`python build_magisk.py` → `build/pico4-power-mode_tuner_magisk_v1.2.zip`

## 工作原理（APK）

Hook `com.picovr.settings` 的 `com.picovr.fragment s.PicolabFragment`：

1. `T0(View)` — 标记电源菜单即将弹出。
2. `PopupMenuHelper.c(...)` — 向菜单注入第三个「性能模式」项（本地化文案）。
3. `U0(int)` — 发布 `2|token|power|<0|1|2>` 请求；等待 V-Sleep 事务结束（精确 ack）
   后调用 `DeviceSwitchUtilsKt.e()` 并强制 eyebuffer（2→2448，其余→1504）；校验后提交
   `effective_owner/phase/ack` 并刷新 UI。
4. `Q(int)` — 按钮/当前方案文字显示「性能模式」。

### 关键细节 / 坑

- 资源字符串被 proguard 混淆，不能反射读 `R.string`；直接 `MenuItemData.l(...)` 设文案。
- `xposed_init` 不能带 UTF-8 BOM。
- 运行时 eyebuffer 的真正来源是 `persist.pvr.config.eyebuffer_width/height` 属性。
- CPU 调优不能由设置应用直接写 sysfs（内核权限 root-only），所以放在 Magisk 伴生模块里以 root 执行。

## 文件结构

```
pico4-power-mode/
├── app/                      # LSPosed 模块工程
├── magisk/                   # Magisk 伴生调优模块（v1.2 新增）
├── build.bat                 # APK 构建
├── build_magisk.py           # Tuner 构建
└── README*.md / COORDINATION.md
```

## 相关

- [pico4-trackerlimit](https://github.com/hhhbwc/pico4-trackerlimit) — 体感追踪器 2.0.5 解锁（v2.7 起单档；性能调优迁移到本项目的 Tuner）
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit) — 2D 悬浮窗数量解锁

## 许可证

MIT
