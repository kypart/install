#!/bin/bash

# 检测操作系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统类型。"
    exit 1
fi
 
# 定义函数来确认用户的选择
confirm_action() {
    while true; do
        read -p "输入 1 删除并停止所有docker容器重新安装，输入 2 退出脚本: " choice
        case $choice in
            1)
                echo "开始删除..."
                # 在这里添加进入容器的命令
                break
                ;;
            2)
                echo "等待一秒后退出脚本..."
                sleep 1
                exit 0
                ;;
            *)
                echo "无效的选择，请重新输入。"
                ;;
        esac
    done
}

# 调用函数确认用户的选择
confirm_action





















# 清理和删除 Docker 和 Docker Compose
echo "开始清理和删除现有的 Docker 和 Docker Compose..."

# 停止所有正在运行的容器
sudo docker stop $(sudo docker ps -aq)

# 删除所有容器
sudo docker rm $(sudo docker ps -aq)

# 删除所有镜像
sudo docker rmi $(sudo docker images -q)

# 删除所有网络
sudo docker network rm $(sudo docker network ls -q)

# 删除所有卷
sudo docker volume rm $(sudo docker volume ls -q) 

# 卸载 Docker 包和相关文件
if [ "$OS" == "ubuntu" ]; then
    sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$OS" == "centos" ]; then
    sudo yum remove -y docker-engine docker docker.io docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "不支持的操作系统。"
    exit 1
fi

# 删除 Docker 相关目录和文件
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm /etc/apparmor.d/docker
sudo groupdel docker
sudo rm -rf /var/run/docker.sock

# 删除 Docker Compose 二进制文件
sudo rm /usr/local/bin/docker-compose
sudo rm /usr/bin/docker-compose

echo "Docker 和 Docker Compose 已成功删除。"

# 更新包索引并安装依赖项
echo "开始安装 Docker 和 Docker Compose..."

if [ "$OS" == "ubuntu" ]; then
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release
elif [ "$OS" == "centos" ]; then
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
fi

# 添加 Docker 官方 GPG 密钥和仓库
if [ "$OS" == "ubuntu" ]; then
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$OS" == "centos" ]; then
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# 启动 Docker 并设置开机自启动
sudo systemctl start docker
sudo systemctl enable docker

# 验证 Docker 安装
sudo docker run hello-world

# 下载 Docker Compose 二进制文件
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 赋予 Docker Compose 可执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建软链接（可选）
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证 Docker Compose 安装
docker-compose --version

echo "Docker 和 Docker Compose 已成功安装。" 
