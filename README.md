# 银灰发少年桌宠

根据角色参考图制作的透明置顶互动桌宠，提供 macOS 与 Windows 安装包。当前版本为 1.3。

## 动作预览

| 待机 | 吃饭 |
| --- | --- |
| ![待机](docs/media/idle.gif) | ![吃饭](docs/media/eat.gif) |
| 睡觉 | 提起与落下 |
| ![睡觉](docs/media/sleep.gif) | ![提起与落下](docs/media/raised.gif) |

其余动作：坐下、生气、疑问、害羞，均在 `docs/media` 中提供 GIF 与 MP4。坐下后保持坐姿，点击角色或再次点击按钮时起身。

## 互动

- 待机：连续呼吸与眨眼；30 秒无操作闭眼，2 分钟无操作睡觉。
- 鼠标悬停：播放疑问动画，持续悬停可能切换为害羞。
- 按住拖动：先提起；鼠标不动时保持稳定悬挂，左右移动时身体按惯性向相反方向摆动。
- 松开鼠标：播放下落、着地与恢复动画。
- 0.55 秒内连续点击至少 3 次：持续生气；继续点击只延长生气时间。
- 侧边按钮：吃饭、睡觉、坐下；睡觉时再互动会苏醒，手动坐下后保持静止直到互动。
- 真实时间：早晚饭点更容易吃饭，午后更容易坐下，深夜更容易睡觉。

## 退出与隐藏

- macOS：右键角色选择退出；`Control + Option + Q` 全局退出，`Control + Option + H` 隐藏或显示。
- Windows：右键角色选择退出；`Ctrl + Alt + Q` 全局退出，`Ctrl + Alt + H` 隐藏或显示。

## 下载与运行

- 从本仓库 Releases 下载对应系统的 ZIP。
- macOS：解压 `银灰发少年桌宠-macOS.zip`，打开应用。首次若被系统拦截，请在“系统设置 → 隐私与安全性”中选择仍要打开。需要 macOS 13 或更新版本。
- Windows：解压 `银灰发少年桌宠-Windows.zip`，双击 `Start-Silver-Pet.bat`。需要 Windows 10 或 Windows 11。

## 从源码构建

- macOS：安装 Python 3 与 Pillow，运行 `./build.sh`。脚本会验证 `ApprovedAnimations` 中的 128 帧，编译并本地签名应用，输出到 `dist/`。
- Windows：安装 Python 3 与 Pillow，运行 `python3 tools/build_windows_package.py`。输出 ZIP 到 `dist/`；运行桌宠时使用系统自带的 PowerShell/WPF。

程序不会联网、不会安装系统服务、不会修改注册表。此项目为非官方个人桌宠项目，请勿用于商业销售或冒充官方产品。仓库公开可见，但未授予代码与角色素材的再分发或商业使用许可。
