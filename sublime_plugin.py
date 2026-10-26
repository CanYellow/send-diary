import sublime
import sublime_plugin
import subprocess
import re
# 在原有的 import re 下方，增加两行：
import tempfile
import os

class SendDiaryCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        
        # 1. 直接提取当前标签页的所有内容，无需保存
        content = view.substr(sublime.Region(0, view.size()))
        if not content.strip():
            sublime.error_message("日记内容为空！")
            return

        # 自动生成临时文件交给 WSL 处理 (彻底免除手动保存)
        temp_fd, win_path = tempfile.mkstemp(suffix=".txt")
        with os.fdopen(temp_fd, 'w', encoding='utf-8') as f:
            f.write(content)
        
        original_file = view.file_name() # 记录用户可能手贱存过的原文件路径

        # 2. Windows 路径转 WSL 路径
        wsl_path = win_path.replace('\\', '/')
        wsl_path = re.sub(r'^([A-Za-z]):/', lambda m: f"/mnt/{m.group(1).lower()}/", wsl_path)

        sublime.status_message("正在通过 WSL (Conda: diary_env) 发送日记...")

        # 3. 组装 WSL 执行命令 (核心修复点)
        # 显式寻找并 source conda.sh，解决非交互式 shell 找不到 conda 的问题
        wsl_script_cmd = (
            "if [ -f ~/miniconda3/etc/profile.d/conda.sh ]; then source ~/miniconda3/etc/profile.d/conda.sh; "
            "elif [ -f ~/anaconda3/etc/profile.d/conda.sh ]; then source ~/anaconda3/etc/profile.d/conda.sh; "
            "elif [ -f ~/miniforge3/etc/profile.d/conda.sh ]; then source ~/miniforge3/etc/profile.d/conda.sh; "
            "else echo 'Error: 找不到 Conda 初始化脚本！' >&2; exit 1; fi && "
            "conda activate diary_env && "
            f"python ~/.local/bin/send_diary.py \"{wsl_path}\""
        )
        
        try:
            # 调用 WSL 执行
            res = subprocess.run(
                ["wsl.exe", "bash", "-c", wsl_script_cmd],
                capture_output=True,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW
            )

            if res.returncode == 0:
                # 如果用户之前手动保存过实体文件，一并连根拔起销毁
                if original_file and os.path.exists(original_file):
                    os.remove(original_file)
                sublime.message_dialog("日记已成功发送并彻底销毁！")
                view.set_scratch(True)
                view.close()

            else:
                sublime.error_message(f"发送失败！\n\n错误信息：\n{res.stderr or res.stdout}")

        except Exception as e:
            sublime.error_message(f"执行脚本发生异常: {str(e)}")
