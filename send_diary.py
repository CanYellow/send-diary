#!/usr/bin/env python3
import sys
import os
import json
import smtplib
from datetime import datetime
from email.mime.text import MIMEText
from email.header import Header

CONFIG_PATH = os.path.expanduser("~/.config/diary/config.json")

def load_config():
    if not os.path.exists(CONFIG_PATH):
        print(f"错误: 找不到配置文件 {CONFIG_PATH}，请先运行 install.sh")
        sys.exit(1)
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

def send_and_delete(file_path):
    config = load_config()
    
    if not os.path.exists(file_path):
        print(f"错误: 文件不存在 {file_path}")
        sys.exit(1)

    # 1. 读取日记内容
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"读取文件失败: {e}")
        sys.exit(1)

    # --- 新增：读取配置并附加落款 ---
    signature = config.get("signature", "")
    if signature:
        content += f"\n\n{signature}"
    # --------------------------------

    # 2. 组装邮件
    today_str = datetime.now().strftime("%Y/%m/%d")
    subject = f"{today_str} diary"

    msg = MIMEText(content, "plain", "utf-8")
    # --- 修改：只对昵称 "Diary" 编码，邮箱地址用尖括号原样拼接 ---
    msg["From"] = f"{Header('myself', 'utf-8')} <{config['sender']}>"
    # --- 修改：收件人纯邮箱地址不需要 Header 编码，直接赋值 ---
    msg["To"] = config["receiver"]
    msg["Subject"] = Header(subject, "utf-8")


    # 3. 发送邮件
    try:
        server = smtplib.SMTP_SSL(config["smtp_server"], config.get("smtp_port", 465))
        server.login(config["sender"], config["auth_code"])
        server.sendmail(config["sender"], [config["receiver"]], msg.as_string())
        server.quit()
        print(">>> 邮件发送成功！")
    except Exception as e:
        print(f">>> 发送邮件失败: {e}")
        sys.exit(1) # 失败则退出，不执行删除

    # 4. 成功后删除文件
    try:
        os.remove(file_path)
        print(f">>> 本地文件已自动清理: {file_path}")
    except Exception as e:
        print(f">>> 删除文件失败: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 send_diary.py <日记文件路径>")
        sys.exit(1)
    send_and_delete(sys.argv[1])
