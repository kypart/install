#!/bin/bash

# 检测是否已经安装了 Kubuntu 桌面
check_kubuntu() {
    echo "检测是否安装了 Kubuntu 桌面..."
    if dpkg-query -l | grep -q "kubuntu-desktop"; then
        echo "Kubuntu 桌面已经安装。"
    else
        echo "Kubuntu 桌面未安装，开始安装..."
        install_kubuntu
    fi
}

# 安装 Kubuntu 桌面系统并配置 XRDP
install_kubuntu() {
    echo "更新服务器并安装 GNOME 桌面和 Dolphin 文件管理器..."
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install tasksel -y
    sudo apt install dolphin -y
    
    echo "安装 Kubuntu 桌面..."
    sudo apt-get install kubuntu-desktop -y

    echo "安装并开启 XRDP 服务..."
    sudo apt install xrdp -y
    sudo systemctl enable xrdp

    echo "添加 2525 端口到防火墙规则..."
    sudo iptables -I INPUT -p tcp --dport 2525 -j ACCEPT
    sudo netfilter-persistent save

    echo "修改 xrdp 配置文件..."
    sudo sed -i 's/port=3389/port=2525/' /etc/xrdp/xrdp.ini
    sudo sed -i '/\[Globals\]/a tcp_send_buffer_bytes=4194304\ntcp_recv_buffer_bytes=6291456\nmax_sessions=1' /etc/xrdp/xrdp.ini

    echo "调整内核 TCP 缓存大小..."
    sudo sysctl -w net.core.rmem_max=12582912
    sudo sysctl -w net.core.wmem_max=8388608
    sudo sysctl -p

    echo "安装完成，重启服务器..."
    sudo reboot
}

# 修复 Kubuntu 桌面环境
repair_desktop() {
    echo "关闭并重新启动 Plasmashell..."
    kquitapp5 plasmashell
    kstart5 plasmashell

    echo "重置 Plasma 配置..."
    mv ~/.config/plasma* ~/.config/plasma_backup/

    echo "重启服务器..."
    sudo reboot
}

# 主菜单函数
main_menu() {
    while true; do
        echo "请选择一个操作："
        echo "1) 检测并安装 Kubuntu 桌面"
        echo "2) 修复 Kubuntu 桌面"
        echo "3) 退出"
        read -p "请输入你的选择 (1, 2, 3): " choice

        case $choice in
            1)
                check_kubuntu
                ;;
            2)
                repair_desktop
                ;;
            3)
                echo "退出脚本"
                exit 0
                ;;
            *)
                echo "无效选择，请输入 1, 2, 或 3."
                ;;
        esac
    done
}

# 调用主菜单
main_menu
