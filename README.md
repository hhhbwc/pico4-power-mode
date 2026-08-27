# PICO 4 高性能电源模式解锁

一个 **LSPosed 模块（1.2，versionCode 3）**，用于在 **PICO 4（A8110）** 的「设置 → 实验室 → 电源管理方案」中解锁隐藏的 **高性能**（High Performance）档位，并作为 `pico_power_coord_v2` 的 Power Mode 端。

> English: [README.en-US.md](README.en-US.md) · Русский: [README.ru-RU.md](README.ru-RU.md)

## 功能

- 在「设置 → 实验室 → 电源管理方案」下拉框里新增第三个 **高性能** 档位（原厂只显示「续航」「标准」两个）。
- 选中「高性能」即调用系统官方切换逻辑（`DeviceSwitchUtilsKt.e()`，对应 `powerlevel=2`）：
  - **eyebuffer 分辨率强制到 2448×2448**（满画质，更清晰）
  - 关闭 **FFR**（固定注视点渲染，消除边缘模糊）
  - 关闭 **stencil mesh**
  - `target_fps=-1`（不限制帧率）
  - 拉起 **CPU/GPU 高性能调度**（`CpuFreqServer onPowerLevelChange 2`）
- **双向强制 eyebuffer**（接管标准/续航档）：
  - 性能模式(2) → **2448×2448**
  - 标准/续航(0/1) → **1504×1504**（回到出厂默认，省电）
- 下拉框选项与按钮文字统一显示为「**性能模式**」而非原厂文案「效果优先」。

## 环境要求

- PICO 4（A8110），已 root
- Magisk + **Zygisk**（内置 Zygisk 实测可用；Zygisk-Next 在本机未成功）
- **Zygisk Vector**（LSPosed 兼容框架，`zygisk_vector` 模块）

## 安装

1. 构建模块（见下方「构建」），或使用 release 里的 `picolab-power.apk`。
2. 安装：`adb install -r app/build/picolab-power.apk`
3. 配置 scope（用 Vector 的 cli，或直接在 Vector 管理器里添加）：

   ```
   su -c '/data/adb/modules/zygisk_vector/cli modules enable com.peaklab.powermode'
   su -c '/data/adb/modules/zygisk_vector/cli scope add com.peaklab.powermode com.picovr.settings'
   ```

4. 重启设置 app（`pkill -f com.picovr.settings`），打开「设置 → 实验室 → 电源管理方案」，即可看到并选择「性能模式」。

## 构建

模块是标准 LSPosed 模块工程，构建依赖：JDK（`--release 8`）、`r8.jar`（D8）、`apktool.jar`、`platform.keystore`。

```
build.bat
```

产物：`app/build/picolab-power.apk`

- javac 必须 `--release 8`（JDK 26 默认 class v52，D8 拒收）。
- Xposed API 使用自写 stub（`app/stub/`），仅编译用，不打进 dex。
- apktool 打包 + jarsigner 自签（无 native lib，无需 zipalign）。

## 工作原理

Hook `com.picovr.settings` 的 `com.picovr.fragments.PicolabFragment`：

1. **`T0(View)`** —— 置标志，表示正在弹出电源模式菜单。
2. **`PopupMenuHelper.c(...)`** —— 反射往电源菜单的 `List<MenuItemData>` 追加第三个「性能模式」项（文本直接用 `MenuItemData.l(CharSequence)` 设置为「性能模式」）。
3. **`U0(int)`** —— 发布唯一 `2|token|power|payload` request（payload 为 0/1/2）；V-Sleep 事务期间异步等待精确 ack 与清理完成，随后才调 `DeviceSwitchUtilsKt.e(context, i)` 并强制 eyebuffer：性能(2)→2448×2448，标准/续航(0/1)→1504×1504。成功校验后才更新 UI。
4. **`Q(int)`** —— 让按钮/当前方案文字在性能模式下显示「性能模式」。

### 关键细节 / 坑

- 字符串资源 `picolab_powerFunc3` 运行时被 proguard 混淆，**不能用反射读 R.string 字段**（会 `NoSuchFieldError`），改为直接 `MenuItemData.l("性能模式")` 设文本，或硬编码资源 ID。
- `xposed_init` 文件**不能带 UTF-8 BOM**（否则类名首字节变乱码 → `ClassNotFoundException`）。
- `T0` 是带 `View` 参数的私有方法（不是无参）。
- 运行时真正决定 eyebuffer 的是 **`persist.pvr.config.eyebuffer_width/height`** 系统属性（不是 `PXRuleValueFile.txt`），所以本模块直接在切换时 setSystemProperties 强制写入 2448/1504。

## 文件结构

```
pico4-power-mode/
├── app/                      # LSPosed 模块工程
│   ├── AndroidManifest.xml
│   ├── aptool.yml
│   ├── assets/xposed_init    # 入口类声明
│   ├── res/values/arrays.xml # xposedscope
│   ├── src/com/peaklab/powermode/PowerModeHook.java  # 入口 hook
│   └── stub/                 # 编译用 Xposed/Android stubs
├── build.bat                 # 构建脚本
└── README.md / README.en-US.md / README.ru-RU.md
```

## 相关

- [pico4-paper_tracker-autostart](https://github.com/hhhbwc/pico4-paper_tracker-autostart) — Paper Tracker 开机自启
- [pico4-winlimit](https://github.com/hhhbwc/pico4-winlimit) — 2D 悬浮窗数量解锁

## 许可证

MIT
