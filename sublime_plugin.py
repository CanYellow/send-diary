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

        # 2. Windows 路径转 WSL 路径 (处理 \ 转义和盘符)
        wsl_path = win_path.replace('\\', '/')
        wsl_path = re.sub(r'^([A-Za-z]):/', lambda m: f"/mnt/{m.group(1).lower()}/", wsl_path)

        sublime.status_message("正在通过 WSL (Conda: diary_env) 发送日记...")

        # 3. 组装 WSL 执行命令 (包含 Conda 环境的初始化、激活、执行与恢复)
        # 使用分号 (;) 确保即使 python 脚本报错，也会执行 conda deactivate 恢复环境
        wsl_script_cmd = (
            "eval \"$(conda shell.bash hook)\" && "
            "conda activate diary_env && "
            f"python ~/.local/bin/send_diary.py \"{wsl_path}\" ; "
            "conda deactivate"
        )
        
        try:
            # 调用 WSL 执行 (使用 -c 运行复合命令)
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
