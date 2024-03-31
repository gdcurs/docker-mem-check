#!/bin/bash

# 提示输入执行脚本
echo "执行脚本:"
read -r custom_command1
# 将双引号转义
custom_command1=${custom_command1//\"/\\\"}

# 生成docker-mem-check.sh脚本
cat << EOF > /root/docker-mem-check.sh
#!/bin/bash

# 自定义语句1
custom_command1="$custom_command1"

# 延迟2分钟后删除所有容器
sleep 2m
if [ "\$(docker ps -aq)" ]; then
    # 存在容器,删除所有容器
    echo "发现存在容器,正在删除所有容器..."
    docker rm -f \$(docker ps -aq)
    echo "所有容器已删除。"
else
    echo "当前没有运行的容器。"
fi
sleep 1m
# 执行自定义语句1
eval \$custom_command1
echo "开始监控。"
count=0
while true
do
    # 延迟3分钟
    #echo "开始监控。"
    sleep 3m
    # 获取所有正在运行的Docker容器ID
    container_ids=\$(docker ps --format "{{.ID}}")

    # 遍历每个容器
    for container_id in \$container_ids
    do
        # 获取容器的内存使用情况(以MB为单位)
        mem_usage=\$(docker stats --no-stream --format "{{.MemUsage}}" \$container_id | awk '{print \$1}' | tr -d '[:alpha:]')
        mem_usage_unit=\$(docker stats --no-stream --format "{{.MemUsage}}" \$container_id | awk '{print \$1}' | tr -d '[:digit:]')
        #echo echo "容器 \$container_id 的使用内存大小为: \$mem_usage+\$mem_usage_unit"
        # 如果内存使用量低于10MB,则删除所有容器并执行自定义语句2
        if (( \$(echo "\$mem_usage < 10" | bc -l) )) || [ "\$mem_usage_unit" = "KiB" ]; then
            sleep 10m
            # 获取容器的内存使用情况(以MB为单位)
            mem_usage=\$(docker stats --no-stream --format "{{.MemUsage}}" \$container_id | awk '{print \$1}' | tr -d '[:alpha:]')
            mem_usage_unit=\$(docker stats --no-stream --format "{{.MemUsage}}" \$container_id | awk '{print \$1}' | tr -d '[:digit:]')
            if (( \$(echo "\$mem_usage < 10" | bc -l) )) || [ "\$mem_usage_unit" = "KiB" ]; then
                if [ "\$(docker ps -aq)" ]; then
                    # 存在容器,删除所有容器
                    echo "发现存在容器,正在删除所有容器..."
                    docker rm -f \$(docker ps -aq)
                    echo "所有容器已删除。"
                else
                    echo "当前没有运行的容器。"
                fi
                sleep 1m
                count=\$((count + 1))                
                eval \$custom_command1
                echo "重启成功，启动次数为\$count"
                break
            fi
        fi
    done
done
EOF

# 给予脚本可执行权限
chmod +x /root/docker-mem-check.sh

# 生成docker-mem-check.service文件
cat << EOF > /etc/systemd/system/docker-mem-check.service
[Unit]
Description=Docker Memory Check
After=docker.service

[Service]
ExecStart=/root/docker-mem-check.sh

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd守护进程
systemctl daemon-reload

# 启用并启动服务
systemctl enable docker-mem-check.service
systemctl start docker-mem-check.service

echo "docker-mem-check.service已生成并启动!"
