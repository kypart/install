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

    # 修改 LANG 和 LANGUAGE 的值
    sudo sed -i 's/^LANG=.*/LANG="zh_CN.UTF-8"/' /etc/default/locale || echo 'LANG="zh_CN.UTF-8"' | sudo tee -a /etc/default/locale
    sudo sed -i 's/^LANGUAGE=.*/LANGUAGE="zh_CN:zh"/' /etc/default/locale || echo 'LANGUAGE="zh_CN:zh"' | sudo tee -a /etc/default/locale

    # 添加其他变量
    for var in LC_NUMERIC LC_TIME LC_MONETARY LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION LC_ALL; do
      sudo sed -i "s/^$var=.*/$var=\"zh_CN\"/" /etc/default/locale || echo "$var=\"zh_CN\"" | sudo tee -a /etc/default/locale
    done

    # 为 LC_ALL 变量设定 UTF-8
    sudo sed -i 's/^LC_ALL=.*/LC_ALL="zh_CN.UTF-8"/' /etc/default/locale || echo 'LC_ALL="zh_CN.UTF-8"' | sudo tee -a /etc/default/locale


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

# 重新安装 Ubuntu 20.04
reinstall_ubuntu_20_04() {
    echo "你确定要重新安装 Ubuntu 20.04 吗？这将会删除现有的数据！（默认密码：AnuBiC_s6）"
    read -p "请输入 'yes' 或 'y' 来确认: " confirmation
    if [[ "$confirmation" == "yes" || "$confirmation" == "y" ]]; then
        echo "更新需要的软件 Ubuntu 20.04..."
        sudo apt update -y && apt install -y curl && apt install -y socat && apt install wget -y xz-utils openssl gawk file
        bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -u 20.04 -v 64 -p "AnuBiC_s6"
    else
        echo "重新安装已取消。"
    fi
}

# 升级到 Ubuntu 22.04
upgrade_to_ubuntu_22_04() {
    echo "升级到 Ubuntu 22.04..."
    #首先需要更新你当前的系统
    sudo apt update
    sudo apt upgrade -y
    sudo apt dist-upgrade -y
    sudo apt autoclean
    sudo apt autoremove -y
    
    #首先更新 apt 源，替换 focal 为 jammy：
    sudo sed -i 's/focal/jammy/g' /etc/apt/sources.list
    sudo sed -i 's/focal/jammy/g' /etc/apt/sources.list.d/*.list
    sudo apt update
    sudo apt upgrade -y
    sudo apt dist-upgrade -y
    
    #更新后删除不必要的软件和依赖：
    sudo apt autoclean
    sudo apt autoremove -y
    sudo reboot
}

# 更换为 163 源
change_to_163_mirrors() {
    echo "更换为 163 源..."
    sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo bash -c "cat << EOF > /etc/apt/sources.list
deb http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF"
    sudo apt update
}

# 主菜单函数
main_menu() {
    while true; do
        echo "请选择一个操作："
        echo "1) 检测并安装 Kubuntu 桌面"
        echo "2) 安装中文语言包"
        echo "3) 修复 Kubuntu 桌面"
        echo "4) 重新安装 Ubuntu 20.04"
        echo "5) 升级到 Ubuntu 22.04"
        echo "6) 更换为 163 源"
        echo "7) 退出"
        read -p "请输入你的选择 (1-7): " choice

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
                reinstall_ubuntu_20_04
                ;;
            5)
                upgrade_to_ubuntu_22_04
                ;;
            6)
                change_to_163_mirrors
                ;;
            7)
                echo "退出脚本"
                exit 0
                ;;
            *)
                echo "无效选择，请输入 1-7."
                ;;
        esac
    done
}

# 调用主菜单
main_menu
