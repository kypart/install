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

# 更新服务器并安装 GNOME 桌面和 Dolphin 文件管理器
install_kubuntu() {
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install tasksel -y
    sudo apt install dolphin -y
    sudo apt-get install kubuntu-desktop -y

    # 安装并开启 XRDP 服务
    sudo apt install xrdp -y
    sudo systemctl enable xrdp

    # 配置 XRDP：启用高效编码、设置TCP
    sudo sed -i '/\[globals\]/a bitmap_compression=yes\nbulk_compression=yes\nuse_compression=yes\ntls_ciphers=HIGH' /etc/xrdp/xrdp.ini
    sudo sed -i '/\[globals\]/a h264=yes\nh264_codec=yes\nrfx_codec=yes\njpeg_codec=yes\nx264=yes\nmax_bpp=16\nmax_sessions=1\ntcp_nodelay=yes' /etc/xrdp/xrdp.ini

    # 添加2525端口并保存防火墙规则
    sudo iptables -I INPUT -p tcp --dport 2525 -j ACCEPT
    sudo netfilter-persistent save

    # 调整网络缓冲区
    sudo sysctl -w net.core.rmem_max=12582912
    sudo sysctl -w net.core.wmem_max=8388608
    sudo sysctl -w net.core.rmem_default=1048576
    sudo sysctl -w net.core.wmem_default=1048576
    sudo sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216'
    sudo sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216'
    sudo sysctl -w net.ipv4.tcp_window_scaling=1
    sudo sysctl -p

    # 修改xrdp端口为2525
    sudo sed -i 's/port=3389/port=2525/' /etc/xrdp/xrdp.ini

    # 禁用 KDE 桌面的合成功能以提高速度
    kwriteconfig5 --file kwinrc --group Compositing --key Enabled false

    # 安装完成后重启
    sudo reboot
}

# 安装中文语言包
install_chinese_language() {
    echo "开始安装中文语言包..."
    sudo apt-get install -y language-pack-zh-han*
    sudo apt install -y $(check-language-support)

    echo "更新 locale 配置文件..."
    sudo sed -i 's/^LANG=.*/LANG="zh_CN.UTF-8"/' /etc/default/locale
    sudo sed -i 's/^LANGUAGE=.*/LANGUAGE="zh_CN:zh"/' /etc/default/locale

    echo "更新环境变量配置..."
    sudo bash -c 'echo -e "\nLANG=\"zh_CN.UTF-8\"\nLANGUAGE=\"zh_CN:zh\"\nLC_NUMERIC=\"zh_CN\"\nLC_TIME=\"zh_CN\"\nLC_MONETARY=\"zh_CN\"\nLC_PAPER=\"zh_CN\"\nLC_NAME=\"zh_CN\"\nLC_ADDRESS=\"zh_CN\"\nLC_TELEPHONE=\"zh_CN\"\nLC_MEASUREMENT=\"zh_CN\"\nLC_IDENTIFICATION=\"zh_CN\"\nLC_ALL=\"zh_CN.UTF-8\"" >> /etc/environment'

    echo "语言包安装完成，请重新登录以应用更改。"
    
    # 安装完成后重启
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
        echo "2) 安装中文语言包"
        echo "3) 修复 Kubuntu 桌面"
        echo "4) 退出"
        read -p "请输入你的选择 (1, 2, 3, 4): " choice

        case $choice in
            1)
                check_kubuntu
                ;;
            2)
                install_chinese_language
                ;;
            3)
                repair_desktop
                ;;
            4)
                echo "退出脚本"
                exit 0
                ;;
            *)
                echo "无效选择，请输入 1, 2, 3, 或 4."
                ;;
        esac
    done
}

# 调用主菜单
main_menu
