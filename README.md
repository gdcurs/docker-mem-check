# 监控并重启IONET脚本（基于容器数量与内存检测）

### 自动生成服务代码并设置开机自动启动
### 当容器数量与内存有问题时自动重启IONET
### 只要输入这串代码到shell中执行，并按提示输入IONET执行代码即可，注意IONET执行代码前可能要加入绝对路径，即输入./root/IONET执行代码




`wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/gdcurs/docker-mem-check/main/generate-docker-mem-check.sh" && chmod 700 /root/generate-docker-mem-check.sh && /root/generate-docker-mem-check.sh`
