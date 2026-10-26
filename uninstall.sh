#!/usr/bin/env bash

echo "======================================"
echo "    日记邮件发送系统 - 卸载与清理     "
echo "======================================"

# ---------------------------------------------------------
# 1. 清理 Conda 环境
# ---------------------------------------------------------
echo ">> 1. 正在检测并清理 Conda 环境 (diary_env)..."
ENV_NAME="diary_env"

# 尝试加载 Conda
if ! command -v conda &> /dev/null; then
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
    fi
else
    eval "$(conda shell.bash hook)"
fi

if command -v conda &> /dev/null; then
    if conda info --envs | grep -q "^$ENV_NAME "; then
        conda env remove -n "$ENV_NAME" -y
        echo ">> Conda 环境 [$ENV_NAME] 已彻底删除。"
    else
        echo ">> Conda 环境 [$ENV_NAME] 不存在，无需清理。"
    fi
else
    echo ">> 未检测到 Conda，跳过环境清理。"
fi
echo ""

# ---------------------------------------------------------
# 2. 清理 WSL 核心脚本软链接
# ---------------------------------------------------------
echo ">> 2. 正在清理 WSL 软链接..."
BIN_FILE="$HOME/.local/bin/send_diary.py"
if [ -L "$BIN_FILE" ] || [ -f "$BIN_FILE" ]; then
    rm -f "$BIN_FILE"
    echo ">> 软链接 $BIN_FILE 已删除。"
else
    echo ">> 软链接不存在，无需清理。"
fi
echo ""

# ---------------------------------------------------------
# 3. 清理配置文件及目录
# ---------------------------------------------------------
echo ">> 3. 正在清理配置文件..."
CONFIG_DIR="$HOME/.config/diary"
if [ -d "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
    echo ">> 配置目录 $CONFIG_DIR 已彻底删除。"
else
    echo ">> 配置目录不存在，无需清理。"
fi
echo ""

# ---------------------------------------------------------
# 4. 清理 Windows 端 Sublime Text 插件
# ---------------------------------------------------------
echo ">> 4. 正在清理 Windows Sublime Text 插件..."
echo "请输入安装时填写的 Sublime Text 'Packages/User' 路径。"
echo "(例如: C:\Users\用户名\AppData\Roaming\Sublime Text\Packages\User)"
read -r -p "请粘贴路径并回车 (直接回车则跳过自动清理): " WIN_SUBLIME_PATH

if [ -n "$WIN_SUBLIME_PATH" ]; then
    # 尝试转换路径，屏蔽错误输出
    WSL_SUBLIME_DIR=$(wslpath -u "$WIN_SUBLIME_PATH" 2>/dev/null || echo "")
    
    if [ -n "$WSL_SUBLIME_DIR" ] && [ -d "$WSL_SUBLIME_DIR" ]; then
        PLUGIN_FILE="$WSL_SUBLIME_DIR/send_diary.py"
        if [ -f "$PLUGIN_FILE" ]; then
            rm -f "$PLUGIN_FILE"
            echo ">> 插件文件 $PLUGIN_FILE 已删除。"
        else
            echo ">> 插件文件不存在，无需清理。"
        fi
    else
        echo "!! 路径转换失败或目录不存在。"
        echo "!! 请手动前往 Windows 对应目录删除 send_diary.py 文件。"
    fi
else
    echo ">> 已跳过插件清理，请手动前往 Windows 目录删除 send_diary.py 文件。"
fi

echo ""
echo "======================================"
echo "卸载完成！系统已恢复至安装前的无损状态。"
echo "【最后一步】:"
echo "请在 Sublime Text 4 中打开 Preferences -> Key Bindings"
echo "手动删除之前添加的 ctrl+alt+d 快捷键配置即可。"
echo "======================================"
