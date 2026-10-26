import sublime
import sublime_plugin
import subprocess
import re

class SendDiaryCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        view = self.view
        
        if not view.file_name():
            sublime.error_message("请先保存当前日记文件！")
            return

        # 1. 自动保存当前文件
        view.run_command("save")
        win_path = view.file_name()

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
            f"python ~/.local/bin/send_diary.py \"{wsl_path}\" ; "
            "conda deactivate"
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
                sublime.message_dialog("日记已成功发送，本地文件已删除！\n(Conda 环境已自动恢复)")
                view.set_scratch(True)
                view.close()
            else:
                sublime.error_message(f"发送失败！\n\n错误信息：\n{res.stderr or res.stdout}")

        except Exception as e:
            sublime.error_message(f"执行脚本发生异常: {str(e)}")
