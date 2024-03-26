#!/bin/bash

# 提示输入执行脚本
echo "执行脚本:"
read -r custom_command1
# 将双引号转义
custom_command1=${custom_command1//\"/\\\"}

# 生成docker-mem-check.sh脚本
cat << EOF > /usr/local/bin/docker-mem-check.sh
#!/bin/bash

# 自定义语句1
custom_command1="$custom_command1"

# 延迟5分钟后删除所有容器
sleep 2m
docker rm -f \$(docker ps -aq)

# 执行自定义语句1
eval \$custom_command1

while true
do
    # 延迟5分钟
    sleep 5m

    # 获取所有正在运行的Docker容器ID
    container_ids=\$(docker ps --format "{{.ID}}")

    # 遍历每个容器
    for container_id in \$container_ids
    do
        # 获取容器的内存使用情况(以KB为单位)
        mem_usage=\$(docker stats --no-stream --format "{{.MemUsage}}" \$container_id | awk '{print \$1}')

        # 将内存使用量从KB转换为MB
        mem_usage_mb=\$((mem_usage / 1024))

        # 如果内存使用量低于10MB,则删除所有容器并执行自定义语句2
        if [ \$mem_usage_mb -lt 10 ]; then
            docker rm -f \$(docker ps -aq)
            eval \$custom_command1
            break
        fi
    done
done
EOF

# 给予脚本可执行权限
chmod +x /usr/local/bin/docker-mem-check.sh

# 生成docker-mem-check.service文件
cat << EOF > /etc/systemd/system/docker-mem-check.service
[Unit]
Description=Docker Memory Check
After=docker.service

[Service]
ExecStart=/usr/local/bin/docker-mem-check.sh

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd守护进程
systemctl daemon-reload

# 启用并启动服务
systemctl enable docker-mem-check.service
systemctl start docker-mem-check.service

echo "docker-mem-check.service已生成并启动!"
