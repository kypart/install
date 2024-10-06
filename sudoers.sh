#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 身份运行此脚本"
  exit 1
fi

# 确定 sudoers 文件路径和需要添加的条目
sudoers_file="/etc/sudoers"
sudoers_entry="ALL ALL=(ALL:ALL) NOPASSWD: /usr/bin/sudo -i"

# 检查 sudoers 文件是否已经包含所需条目
if grep -Fxq "$sudoers_entry" "$sudoers_file"; then
  echo "sudoers 文件中已存在免密码 sudo -i 的配置。"
else
  # 创建一个备份
  cp "$sudoers_file" "$sudoers_file.bak"

  # 使用临时文件编辑 sudoers
  tmp_sudoers=$(mktemp)
  cp "$sudoers_file" "$tmp_sudoers"

  # 添加免密行
  echo "$sudoers_entry" >> "$tmp_sudoers"

  # 使用 visudo 检查语法
  visudo -c -f "$tmp_sudoers"
  if [ $? -eq 0 ]; then
    # 如果没有语法错误，将临时文件替换掉原文件
    cp "$tmp_sudoers" "$sudoers_file"
    echo "sudoers 文件修改成功！"
  else
    echo "sudoers 文件语法错误，修改失败。"
  fi

  # 删除临时文件
  rm "$tmp_sudoers"
fi
