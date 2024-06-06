clear
echo -e "\e[32m#############################################################\e[0m"
echo -e "\e[32m# Usage:    常用脚本管理 GitHub Copilot                       #\e[0m"
echo -e "\e[32m# Website:  https://cloudflare.com/                          #\e[0m"
echo -e "\e[32m# Author:   emal <noray@cloudflare.com.com>                  #\e[0m"
echo -e "\e[32m# Github:   https://github.com/                              #\e[0m"
echo -e "\e[32m#############################################################\e[0m"
echo

#!/bin/bash

# Array of URLs with corresponding descriptions
urls=(
    "https://git.io/hysteria.sh hysteria脚本"
    "https://git.io/oneclick  trojan_v2ray脚本"
    "https://raw.githubusercontent.com/localpoliy/install/local/bbr.sh BBR_脚本"
    "https://raw.githubusercontent.com/localpoliy/install/local/nginx.sh Nginx_脚本"
    "https://raw.githubusercontent.com/localpoliy/install/local/firewall.sh 防火墙脚本"
    "https://raw.githubusercontent.com/localpoliy/install/local/iptablesUtils.sh iptables_脚本"
     "https://raw.githubusercontent.com/localpoliy/install/local/install_script.sh 兔哥一键脚本"
    "https://raw.githubusercontent.com/localpoliy/install/local/wordpress_redis.sh WordPress_Redis_脚本"
    "退出脚本"
)

# Function to display options
show_options() {
    echo "请选择要运行的脚本："
    index=1
    for url_desc in "${urls[@]}"; do
        #echo "$index. ${url_desc##* }"
        echo -e "\e[32m$index. ${url_desc##* }\e[0m"
        ((index++))
    done
}

# Function to run selected script
run_selected() {
    read -p "请输入要运行的脚本的编号: " choice
    choice=$((choice-1)) # Decrement by 1 to match array index
    if [ $choice -ge 0 ] && [ $choice -lt ${#urls[@]} ]; then
       if [ $choice -eq $(( ${#urls[@]} - 1 )) ]; then
           echo "退出脚本"
           exit 0
        else
        url="${urls[$choice]}"
        echo "Running script from ${url##* }"
        bash <(curl -fsSL "${url%% *}")
        echo "脚本 ${url##* } 运行完成"
             fi
    else
        echo "输入无效，请重新运行脚本并选择正确的编号。"
    fi
}

# Main
show_options
run_selected
