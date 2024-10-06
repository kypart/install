#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 身份运行此脚本"
  exit 1
fi

# 检查 sudoers 文件是否已经有相关的免密配置
sudoers_entry="ALL ALL=(ALL) NOPASSWD: /usr/bin/sudo -i"
if sudo grep -Fxq "$sudoers_entry" /etc/sudoers; then
  echo "sudoers 文件中已经存在免密配置，无需修改。"
else
  # 使用临时文件编辑 sudoers 文件
  echo "正在修改 sudoers 文件..."

  # 临时文件创建
  tmp_sudoers=$(mktemp)
  sudo cp /etc/sudoers $tmp_sudoers

  # 添加免密行
  echo "$sudoers_entry" >> $tmp_sudoers

  # 用 visudo 检查并应用更改
  sudo visudo -c -f $tmp_sudoers
  if [ $? -eq 0 ]; then
    sudo cp $tmp_sudoers /etc/sudoers
    echo "sudoers 文件修改成功！"
  else
    echo "sudoers 文件有语法错误，修改失败。"
  fi

  # 删除临时文件
  rm $tmp_sudoers
fi
