#!/bin/bash

# Nginx配置文件路径
nginx_conf_path="/etc/nginx/conf.d/nginx.conf"

# 红色文字输出
function Echo_Red() {
    echo -e "\033[31m$1\033[0m"
}

# 检查系统是否为Ubuntu，如果不是则退出脚本
function checkUbuntu() {
    if [[ "$(uname -s)" != "Linux" || ! -e "/etc/os-release" || ! "$(grep -E '^ID=' /etc/os-release | cut -d'=' -f2)" =~ "ubuntu" ]]; then
        Echo_Red "错误：该脚本仅适用于Ubuntu系统。退出。"
        exit 1
    fi
}

# 检查Nginx是否安装，如果没有安装则自动安装
function installNginx() {
    checkUbuntu
    if ! command -v nginx &> /dev/null; then
        Echo_Red "安装 Nginx..."
        sudo apt-get update
        sudo apt-get install -y nginx
    else
        nginx_version=$(nginx -v 2>&1 | awk -F '/' 'NR==1{print $2}')
        if [ $? -eq 0 ]; then
            Echo_Red "Nginx 已安装，版本：$nginx_version"
        else
            Echo_Red "无法获取 Nginx 版本信息。"
        fi
    fi

    sleep 2
}

# 查看Nginx配置文件中的域名和端口
function viewNginxConfig() {
    if grep -q "server_name" "$nginx_conf_path"; then
        Echo_Red "已有的域名和端口:"
        awk '/server_name/ {
            domain = $2;
            sub(/;/, "", domain);
            domain_list[++count] = domain;
        } /proxy_pass http:\/\/127.0.0.1:([0-9]+);/ {
            split($0, arr, ":");
            port = substr(arr[3], 1, length(arr[3])-1);
            port_list[count] = port;
        } END {
            for (i = 1; i <= count; i++) {
                print i ": " domain_list[i] " 端口：" port_list[i];
            }
        }' "$nginx_conf_path"
    else
        Echo_Red "配置文件中未找到server_name项。"
    fi
    read -n 1 -s -r -p "按任意键继续..."
}

# 用户交互添加域名和端口到Nginx配置文件
function addDomainPort() {
    checkUbuntu
    Echo_Red "请输入域名（例如：example.com）："
    read -r domain
    Echo_Red "请输入端口号："
    read -r port

    # 在配置文件末尾添加新的server块
    echo -e "\nserver {" >> "$nginx_conf_path"
    echo -e "  listen 80;" >> "$nginx_conf_path"
    echo -e "  server_name $domain;" >> "$nginx_conf_path"
    echo -e "\n  location / {" >> "$nginx_conf_path"
    echo -e "    proxy_pass http://127.0.0.1:$port;" >> "$nginx_conf_path"
    echo -e "    proxy_set_header Host \$host;" >> "$nginx_conf_path"
    echo -e "    proxy_set_header X-Real-IP \$remote_addr;" >> "$nginx_conf_path"
    echo -e "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> "$nginx_conf_path"
    echo -e "  }\n}" >> "$nginx_conf_path"
    Echo_Red "域名和端口已成功添加到Nginx配置文件。"
    read -n 1 -s -r -p "按任意键继续..."
}

# 删除指定域名的服务器块
function deleteDomainPort() {
    viewNginxConfig
 
    echo 
    Echo_Red "请输入要删除的域名（例如：example.com），或输入 'c' 取消:"
    read -r domain_name

    # 检查是否输入 'c' 取消
    if [[ "$domain_name" == "c" ]]; then
        Echo_Red "取消删除，未做任何改变。"
    else
        # 获取匹配域名的行号
        line_number=$(awk -v domain="$domain_name" '$0 ~ ("server_name " domain ";") {print NR}' "$nginx_conf_path")

        # 检查是否找到匹配的内容
        if [[ -n "$line_number" ]]; then
            # 删除匹配的整个 server 块（包括匹配域名的一行，上2行和下8行）
            awk -v start=$((line_number-2)) -v end=$((line_number+8)) 'NR>=start && NR<=end {next} 1' "$nginx_conf_path" > temp_config && mv temp_config "$nginx_conf_path"
            Echo_Red "域名和端口已成功删除。"
        else
            Echo_Red "找不到对应行，未做任何改变。"
        fi
    fi

    # 无需重启 Nginx
    read -n 1 -s -r -p "按任意键继续..."
}

#重启Nginx
function restartNginx() {
    checkUbuntu
    sudo service nginx restart
    Echo_Red "Nginx已成功重启。"
    read -n 1 -s -r -p "按任意键继续..."
}

# 查看Nginx运行状态
function checkNginxStatus() {
    checkUbuntu
    sudo service nginx status
    read -n 1 -s -r -p "按任意键继续..."
}

# 主菜单
function main() {
    clear
    Echo_Red "使用 Nginx 管理程序！ "
    Echo_Red "============================================"
    echo "1. 检查/安装 Nginx"
    echo "2. 查看 Nginx 域名和端口"
    echo "3. 添加域名和端口"
    echo "4. 删除域名和端口"
    echo "5. 重启 Nginx"
    echo "6. 查看 Nginx 运行状态"
    echo "7. 退出 Nginx 管理脚本"
    Echo_Red "============================================"
    read -r -p "请输入选项（1-7）: " option

    case $option in
        1)
            installNginx
            ;;
        2)
            viewNginxConfig
            ;;
        3)
            addDomainPort
            ;;
        4)
            deleteDomainPort
            ;;
        5)
            restartNginx
            ;;
        6)
            checkNginxStatus
            ;;
        7)
            Echo_Red "退出 Nginx 管理脚本。"
            exit 0
            ;;
        *)
            Echo_Red "无效选项，请重新输入。"
            read -n 1 -s -r -p "按任意键继续..."
            ;;
    esac
    main
}

# 启动主菜单
main

