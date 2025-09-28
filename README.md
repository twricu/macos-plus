# macOS-Plus

**macOS-Plus** 是基于 [Hammerspoon](https://www.hammerspoon.org/) 的 macOS 增强工具，让键盘、鼠标和系统操作更高效。

👉 [点击查看视频演示](https://www.bilibili.com/video/BV1DVVkzDExQ)

## 功能概览

### 鼠标

- 滚轮线性滚动，每次 3 行，按住 `Option` 加速
- 鼠标侧键切换左右桌面

### 键盘

- **`CapsLock` 映射为 `Hyper`（`F13`）键**
- `Hyper` + `H/J/K/L` → 光标移动（Vim 风格）
- `Hyper` + `↑/↓/←/→` → 窗口分屏或全屏
- `Hyper` + `I/O` → 切换标签页
- `Hyper` + `P` → 防止系统休眠
- `Hyper` + `G` → 开关音量
- `Hyper` + `R/F/Space/V` → 快捷启动（终端、访达、启动台、剪贴板）
- `Hyper` + `?` → 快捷启动自定义应用

- **短击 `CapsLock` 发送 `Esc` 键**
- **单击 `Shift` → 切换输入法**

### 系统

- 输入法切换弹窗
- 聚焦应用自动切换输入法
- 定时同步文件到 iCloud

## 安装

1. 安装 [Hammerspoon](https://www.hammerspoon.org/)
2. 将脚本放入 `~/.hammerspoon/init.lua`
3. 打开 Hammerspoon → `Reload Config`

## 插件依赖

- **[ClipboardTool](https://www.hammerspoon.org/Spoons/ClipboardTool.html)**：用于剪贴板管理（已随仓库打包）
- 更多插件可在 [Spoons 官网](https://www.hammerspoon.org/Spoons/) 查看
