#!/bin/bash

# 设置 DEBIAN_FRONTEND 环境变量为 noninteractive 模式
export DEBIAN_FRONTEND=noninteractive

# 更新软件包列表
apt update

apt install vim curl -y

# 升级已安装的软件包
apt -y upgrade

# 执行发行版升级
apt -y dist-upgrade

# 清理不需要的包
apt -y autoclean
apt -y autoremove

# 更改软件源为 jammy
sed -i 's/focal/jammy/g' /etc/apt/sources.list
sed -i 's/focal/jammy/g' /etc/apt/sources.list.d/*.list

# 更新软件包列表
apt update

# 再次升级软件包
apt -y upgrade
apt -y dist-upgrade

# 清理不需要的包
apt -y autoclean
apt -y autoremove

# 重启系统
reboot
