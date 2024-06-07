#!/bin/bash

# 更新服务器并安装Ubuntu桌面系统
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install tasksel -y
sudo tasksel install ubuntu-desktop

# 安装并启用xrdp服务
sudo apt-get install xrdp -y
sudo systemctl enable xrdp

# 添加2525端口规则
sudo iptables -I INPUT -p tcp --dport 2525 -j ACCEPT
sudo netfilter-persistent save

# 修改xrdp配置文件
sudo sed -i 's/port=3389/port=2525/' /etc/xrdp/xrdp.ini
echo "max_sessions=1" | sudo tee -a /etc/xrdp/xrdp.ini
echo "tcp_send_buffer_bytes=4194304" | sudo tee -a /etc/xrdp/xrdp.ini
echo "tcp_recv_buffer_bytes=6291456" | sudo tee -a /etc/xrdp/xrdp.ini

# 应用sysctl设置
sudo sysctl -p

# 重启系统
sudo reboot
