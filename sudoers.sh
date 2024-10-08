#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 身份运行此脚本"
  exit 1
fi

# 确定 sudoers.d 目录路径和需要添加的文件名
sudoers_d_dir="/etc/sudoers.d"
sudoers_file="$sudoers_d_dir/nopasswd_sudo_i"
sudoers_entry="ALL ALL=(ALL) NOPASSWD: /usr/bin/sudo -i"

# 检查 sudoers.d 目录是否存在
if [ ! -d "$sudoers_d_dir" ]; then
  echo "sudoers.d 目录不存在，创建目录..."
  mkdir "$sudoers_d_dir"
fi

# 检查配置文件是否已经包含所需条目
if grep -Fxq "$sudoers_entry" "$sudoers_file"; then
  echo "sudoers.d 文件中已存在免密码 sudo -i 的配置。"
else
  # 创建或追加免密配置
  echo "$sudoers_entry" > "$sudoers_file"

  # 确保权限为 0440
  chmod 0440 "$sudoers_file"

  # 使用 visudo 检查语法
  visudo -c -f "$sudoers_file"
  if [ $? -eq 0 ]; then
    echo "sudoers.d 文件修改成功，免密码 sudo -i 配置已生效！"
  else
    echo "sudoers 文件语法错误，修改失败。"
    # 如果检查失败，删除文件以避免问题
    rm "$sudoers_file"
  fi
fi
