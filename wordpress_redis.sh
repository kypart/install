#!/bin/bash

# 提示用户只能在容器内运行脚本
echo "警告：此脚本只能在容器内运行！并且已经安装好wordpres 主题 和redis 容器"

# 定义函数来确认用户的选择
confirm_action() {
    while true; do
        read -p "输入 1 容器运行，输入 2 退出脚本: " choice
        case $choice in
            1)
                echo "进入容器..."
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

echo "# 更新包列表并安装必要的构建工具"
apt update && apt install -y build-essential autoconf

# 安装 PECL 和必要的库
apt install -y liblz4-dev libzstd-dev vim
echo "#安装 igbinary 扩展"
pecl install igbinary

echo "# 下载 Redis 扩展"
REDIS_TGZ=$(pecl download redis | awk '/^downloading/ {print $2}')
tar -xzf $REDIS_TGZ
DIR_NAME=$(basename $REDIS_TGZ .tgz)
cd $DIR_NAME

echo "# 编译和安装 Redis 扩展"
phpize
./configure --enable-redis-igbinary
make
make install

# 清理下载的文件
rm -rf $DIR_NAME $REDIS_TGZ

echo "Redis 和必要的扩展已成功安装。"

# 停止一秒钟
sleep 2

echo "# 获取 WordPress 容器内 wp-config.php 文件的路径"
 
WP_CONFIG_PATH=$(find /var/www/html -name wp-config.php)
echo " "
# 检查是否已经包含了 Redis 配置信息，如果没有则写入
if ! grep -q "define('WP_REDIS_CONFIG" "$WP_CONFIG_PATH"; then
    echo "# 添加 Redis 配置信息到 wp-config.php 文件"
    sed -i "/<?php/a \\
define('WP_REDIS_CONFIG', [ \\
    'token' => 'UZAUdrg3LSPMAUL4g3QSjF3HcJUaRm8qk5nFqq8QPQSs6H9LWDvYXvkDYVis', \\
    'host' => 'redis', \\
    'port' => 6379, \\
    'database' => 0, \\
    'maxttl' => 86400 * 7, \\
    'timeout' => 1.0, \\
    'retry_interval' => 100, \\
    'retries' => 3, \\
    'backoff' => 'smart', \\
    'async_flush' => true, \\
    'split_alloptions' => true, \\
    'prefetch' => true, \\
    'strict' => true, \\
    'debug' => false, \\
    'save_commands' => false, \\
]); \\
define('WP_REDIS_DISABLED', false); \\
" $WP_CONFIG_PATH
fi

echo "# 备份原始 PHP 配置文件 文件路径"
cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
# 停止一秒钟
sleep 2

echo "# 修改 PHP 配置文件"
PHP_INI=$(php -r "echo php_ini_loaded_file();")

echo "# 将扩展添加到 php.ini 文件中，如果已经存在则不添加"
if ! grep -q "extension=redis.so" "$PHP_INI"; then
    sed -i '/^\[PHP\]/a extension=redis.so' $PHP_INI
fi

sed -i 's/^;\?\(memory_limit\).*/\1 = 512M/g' $PHP_INI
sed -i 's/^;\?\(post_max_size\).*/\1 = 256M/g' $PHP_INI
sed -i 's/^;\?\(upload_max_filesize\).*/\1 = 128M/g' $PHP_INI
sed -i 's/^;\?\(max_file_uploads\).*/\1 = 20/g' $PHP_INI
sed -i 's/^;\?\(max_execution_time\).*/\1 = 600/g' $PHP_INI
sed -i 's/^;\?\(max_input_time\).*/\1 = 600/g' $PHP_INI
sed -i 's/^;\?\(max_input_vars\).*/\1 = 5000/g' $PHP_INI

echo "WordPress 容器内的脚本执行完成。"
