#!/usr/bin/env bash
set -e

CONFIG_DIR="$HOME/.config/diary"
CONFIG_FILE="$CONFIG_DIR/config.json"
BIN_DIR="$HOME/.local/bin"
ENV_NAME="diary_env"

echo "======================================"
echo "    日记邮件发送系统 - 安装配置       "
echo "======================================"

# ---------------------------------------------------------
# 1. Conda 环境自动化检测与创建
# ---------------------------------------------------------
echo ">> 1. 正在检测 Conda 环境..."

# 尝试在非交互式脚本中加载 Conda
if ! command -v conda &> /dev/null; then
    # 如果环境变量里没有，尝试从常见默认路径加载
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
    else
        echo "!! 错误: 找不到 Conda。请确保已安装 Anaconda 或 Miniconda。"
        exit 1
    fi
else
    eval "$(conda shell.bash hook)"
fi

# 检查环境是否存在，不存在则自动创建
if conda info --envs | grep -q "^$ENV_NAME "; then
    echo ">> Conda 环境 [$ENV_NAME] 已存在，跳过创建。"
else
    echo ">> 未找到 [$ENV_NAME] 环境，正在自动创建 (Python 3.10)..."
    conda create -n "$ENV_NAME" python=3.10 -y
    echo ">> Conda 环境 [$ENV_NAME] 创建成功！"
fi
echo ""

# ---------------------------------------------------------
# 2. 创建目录并设置 WSL 软链接
# ---------------------------------------------------------
echo ">> 2. 正在配置核心脚本..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$BIN_DIR"
ln -sf "$(pwd)/send_diary.py" "$BIN_DIR/send_diary.py"
chmod +x "$(pwd)/send_diary.py"
echo ">> 核心脚本已链接至 $BIN_DIR/send_diary.py"
echo ""

# ---------------------------------------------------------
# 3. 邮箱配置 (交互式)
# ---------------------------------------------------------
echo ">> 3. 邮箱授权配置..."
if [ -f "$CONFIG_FILE" ]; then
    read -p "已存在配置文件，是否重新设置？(y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "跳过邮箱配置。"
        CONFIG_EXISTS=1
    fi
fi

if [ -z "$CONFIG_EXISTS" ]; then
    read -p "请输入发送邮箱 A (如: userA@163.com): " SENDER
    read -p "请输入接收邮箱 B (如: userB@163.com): " RECEIVER
    read -p "请输入当前电脑专属的网易授权码 (不回显): " -s AUTH_CODE
    echo ""
    read -p "请输入 SMTP 服务器 [默认: smtp.163.com]: " SMTP_SERVER
    SMTP_SERVER=${SMTP_SERVER:-smtp.163.com}
    # --- 新增：提示输入自定义落款 ---
    read -p "请输入邮件末尾的自定义落款 (如: -- 来自我的Win10): " SIGNATURE

    cat > "$CONFIG_FILE" <<EOF
{
  "sender": "$SENDER",
  "receiver": "$RECEIVER",
  "auth_code": "$AUTH_CODE",
  "smtp_server": "$SMTP_SERVER",
  "smtp_port": 465,
  "signature": "$SIGNATURE"
}
EOF

    chmod 600 "$CONFIG_FILE"
    echo ">> 配置文件已生成至: $CONFIG_FILE"
fi
echo ""

# ---------------------------------------------------------
# 4. 配置 Sublime Text 4 插件
# ---------------------------------------------------------
echo "======================================"
echo "4. 配置 Sublime Text 4 插件"
echo "======================================"
echo "请在 Windows 中打开 Sublime Text 4，点击菜单栏: Preferences -> Browse Packages..."
echo "复制弹出的文件夹路径 (例如: C:\Users\用户名\AppData\Roaming\Sublime Text\Packages)"
echo "然后在该路径后加上 \User"
echo "最终路径格式类似: C:\Users\用户名\AppData\Roaming\Sublime Text\Packages\User"
echo ""

# 使用 read -r 确保 Windows 路径中的反斜杠 \ 不会被转义吞掉
read -r -p "请粘贴上述 Windows 路径并回车: " WIN_SUBLIME_PATH

# 使用 wslpath -u 将 Windows 路径转换为 WSL 路径
WSL_SUBLIME_DIR=$(wslpath -u "$WIN_SUBLIME_PATH")

if [ -d "$WSL_SUBLIME_DIR" ]; then
    cp "$(pwd)/sublime_plugin.py" "$WSL_SUBLIME_DIR/send_diary.py"
    echo ">> 成功！插件已复制到: $WSL_SUBLIME_DIR/send_diary.py"
else
    echo "!! 错误: 找不到转换后的目录 $WSL_SUBLIME_DIR"
    echo "!! 请检查你输入的 Windows 路径是否正确，并手动将 sublime_plugin.py 复制进去。"
fi

echo ""
echo "======================================"
echo "安装与环境搭建全部完成！最后一步："
echo "请在 Sublime Text 4 中点击 Preferences -> Key Bindings"
echo "添加以下快捷键绑定："
echo '[ { "keys": ["ctrl+alt+d"], "command": "send_diary" } ]'
echo "======================================"
