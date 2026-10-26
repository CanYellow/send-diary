# 📝 Sublime-WSL Diary Sender (日记一键发送系统)

![Python](https://img.shields.io/badge/Python-3.10-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20WSL-lightgrey.svg)
![Sublime Text](https://img.shields.io/badge/Sublime%20Text-4-orange.svg)

这是一个基于 **Windows (Sublime Text 4) + WSL (Linux)** 架构的极简日记写作与发送工具。

通过本工具，你可以在 Windows 下使用 Sublime Text 优雅地撰写日记，完成后只需按下快捷键 `Ctrl+Alt+D`，系统便会自动唤醒 WSL 后台，在独立的 Conda 环境中将日记发送至指定邮箱，并**自动销毁本地原文件**，确保隐私安全。

## ✨ 核心特性

- **一键发送与阅后即焚**：写完即发，发完即删，本地不留痕迹。
- **跨系统无缝协同**：前端在 Windows (Sublime Text) 编写，后端在 WSL (Linux) 独立环境执行，互不干扰。
- **全自动环境隔离**：安装脚本会自动在 WSL 中创建专属的 Conda 环境 (`diary_env`)，不污染系统自带的 Python 环境。
- **完美解决非交互式 Shell 痛点**：深度优化 WSL 后台调用逻辑，精准定位 Conda 初始化脚本，告别 `command not found`。
- **无损卸载**：提供一键卸载脚本，保证系统恢复至安装前的纯净状态。

---

## 🛠️ 准备工作 (Prerequisites)

在安装之前，请确保你的电脑满足以下条件：

1. **Windows 系统**：已安装并启用 **WSL** (推荐 Ubuntu)。
2. **Sublime Text 4**：已安装在 Windows 系统中。
3. **Conda 环境**：WSL 中已安装 Anaconda、Miniconda 或 Miniforge。
4. **邮箱授权码**：准备一个开启了 SMTP 服务的邮箱（如网易 163、QQ 邮箱等），并获取**专属授权码**（非登录密码）。

---

## 🚀 安装指南 (Installation)

### 1. 获取代码
在 **WSL 终端** 中，克隆或下载本项目到本地：
```bash
git clone https://github.com/你的用户名/你的仓库名.git
cd 你的仓库名
```

### 2. 一键安装
在 **WSL 终端** 中运行安装脚本：
```bash
chmod +x install.sh
./install.sh
```
**安装脚本会自动完成以下工作：**
- 检测并自动创建 Conda 专属环境 (`diary_env`, Python 3.10)。
- 引导你输入发件邮箱、收件邮箱及 SMTP 授权码，并加密生成配置文件。
- 引导你输入 Windows 下 Sublime Text 的 `Packages/User` 路径，自动将插件推送至 Windows 端。

### 3. 配置快捷键
打开 Windows 端的 Sublime Text 4，点击菜单栏：
`Preferences` -> `Key Bindings`
在右侧的用户配置文件中，添加以下快捷键绑定：
```json
[
    { "keys": ["ctrl+alt+d"], "command": "send_diary" }
]
```
*(如果你已有其他快捷键，请注意在上一项末尾加逗号 `,`)*

---

## 📖 使用说明 (Usage)

1. 在 Windows 中打开 Sublime Text 4，新建一个文件，开始撰写你的日记。
2. 写完后，2. 写完后，**无需保存**，直接按下快捷键 **`Ctrl+Alt+D`** 即可发送。
3. 底部状态栏会提示发送进度。发送成功后，会弹出成功提示框，**当前标签页会自动关闭，且本地文件会被彻底删除**。

---

## 🗑️ 卸载与清理 (Uninstallation)

如果你不再需要本工具，可以通过卸载脚本实现**100% 无损清理**。

在 **WSL 终端** 的项目目录下运行：
```bash
chmod +x uninstall.sh
./uninstall.sh
```
**卸载脚本会自动：**
- 彻底移除 `diary_env` Conda 环境。
- 删除 WSL 中的软链接和配置文件目录 (`~/.config/diary`)。
- 引导你删除 Windows 端的 Sublime 插件文件。

**最后一步：**
手动打开 Sublime Text 的 `Preferences` -> `Key Bindings`，删除之前添加的 `ctrl+alt+d` 快捷键即可。

---

## 🏗️ 架构说明 (Architecture)

- **`install.sh` / `uninstall.sh`**: 负责生命周期管理，自动化部署与清理。
- **`send_diary.py` (WSL 端)**: 核心业务逻辑，负责读取文件、构建 MIME 邮件、连接 SMTP 服务器发送邮件，并执行文件删除操作。
- **`sublime_plugin.py` (Windows 端)**: Sublime Text 插件，负责捕获快捷键、将 Windows 路径转换为 WSL 路径 (`/mnt/c/...`)，并通过 `wsl.exe bash -c` 显式加载 Conda 环境并执行后端脚本。

---

## 📄 许可证 (License)

本项目采用 [MIT License](LICENSE) 开源许可证。你可以自由地使用、修改和分发本项目的代码。