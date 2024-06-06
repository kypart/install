#!/bin/bash

# 颜色定义
LIGHT_GREEN='\033[1;32m'
LIGHT_RED='\033[1;31m'
NO_COLOR='\033[0m'

# 检查和安装 firewall
check_and_install_firewalld() {
    if ! systemctl list-units --type=service | grep -q firewalld.service; then
        echo "firewalld未安装，正在安装..."
        sudo apt update
        sudo apt install firewalld -y
        sudo ufw disable
    fi
}

# 检查并配置 firewalld 开机自启动
enable_firewalld_on_boot() {
    if ! systemctl is-enabled firewalld > /dev/null; then
        echo "配置 firewalld 开机自启动..."
        sudo systemctl enable firewalld
    fi
}

# 检查并启动 firewalld
ensure_firewalld_running() {
    if ! systemctl is-active --quiet firewalld; then
        echo "启动 firewalld..."
        sudo systemctl start firewalld
    fi
}

# 启动防火墙函数
start() {
    if systemctl is-active --quiet firewalld; then
        echo "防火墙运行中"
    else
        sudo systemctl start firewalld
        echo "防火墙已启动"
    fi
}

# 停止防火墙函数
stop() {
    if systemctl is-active --quiet firewalld; then
        sudo systemctl stop firewalld
        echo "防火墙已停止"
    else
        echo "防火墙已经停止"
    fi
}

# 添加端口函数
add_port() {
    read -p "请输入要添加的端口号：" port
    sudo firewall-cmd --zone=public --add-port="${port}/tcp" --permanent
    sudo firewall-cmd --zone=public --add-port="${port}/udp" --permanent
    sudo firewall-cmd --reload
    echo "端口$port已添加"
}

# 删除端口函数
delete_port() {
    read -p "请输入要删除的端口号：" port
    sudo firewall-cmd --zone=public --remove-port="${port}/tcp" --permanent
    sudo firewall-cmd --zone=public --remove-port="${port}/udp" --permanent
    sudo firewall-cmd --reload
    echo "端口$port已删除"
}

# 查看已打开的端口函数
list_port() {
    echo -e "${LIGHT_GREEN}已打开的端口：${NO_COLOR}"
    firewall-cmd --zone=public --list-ports
    countdown_to_clear
}

# 查看防火墙状态函数
status() {
    sudo systemctl status firewalld
    countdown_to_clear
}

# 清屏函数
clear_screen() {
    clear
}

# 倒计时清屏函数
countdown_to_clear() {
    for i in {5..1}; do
        echo -ne "${LIGHT_RED}倒计时 ${i} 秒后清屏${NO_COLOR}\r"
        sleep 1
    done
    clear_screen
}

# 查看防火墙状态子菜单
firewall_status_menu() {
    while true; do
        clear_screen
        echo -e "${LIGHT_GREEN}————————————————————————————"
        echo "Firewalld 防火墙状态查看"
        echo "1. 开启防火墙"
        echo "2. 关闭防火墙"
        echo "3. 防火墙状态"
        echo "4. 返回上一级菜单"
        echo "5. 退出"
        echo -e "${NO_COLOR}"
        read -p "请输入操作选项：" option
        case "$option" in
            1) start ;;
            2) stop ;;
            3) status ;;
            4) clear_screen; return ;;
            5) exit ;;
            *) echo "无效的选项" && sleep 2 ;;
        esac
    done
}

# 主菜单
menu() {
    while true; do
        clear_screen
        echo -e "${LIGHT_GREEN}————————————————————————————"
        echo "Firewalld 防火墙管理"
        echo "1. 查看防火墙状态"
        echo "2. 查看已打开的端口"
        echo "3. 添加端口"
        echo "4. 删除端口"
        echo "5. 退出"
        echo -e "${NO_COLOR}"
        read -p "请输入操作选项：" option
        case "$option" in
            1) firewall_status_menu ;;
            2) list_port ;;
            3) add_port ;;
            4) delete_port ;;
            5) exit ;;
            *) echo "无效的选项" && sleep 1 ;;
        esac
    done
}

# 检查和安装 firewalld
check_and_install_firewalld

# 配置 firewalld 开机自启动
enable_firewalld_on_boot

# 确保 firewalld 正在运行
ensure_firewalld_running

# 显示主菜单
menu
