#!/bin/bash

# 检查是否以 root 用户运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 默认参数
DEFAULT_STREAMS=32
DEFAULT_RESOLUTION="1920x1080"
DEFAULT_STORAGE="/var/rtsp_recordings"

# 安装依赖
echo "安装依赖..."
apt update
apt install -y nodejs npm

# 安装 Node.js 依赖
echo "安装 Node.js 依赖..."
npm install express body-parser cors

# 移动文件到目标目录
echo "移动文件到目标目录..."
mv /opt/rtsp_recorder/* /opt/rtsp_recorder/
mv /WWW/rtsp_recorder/* /var/www/rtsp_recorder/

# 设置登录页面
echo "设置登录页面为 login.html..."
ln -s /var/www/rtsp_recorder/login.html /var/www/rtsp_recorder/index.html

# 打开防火墙端口3000
echo "打开防火墙端口3000..."
ufw allow 3000

# 启动应用
echo "启动应用..."
cd /opt/rtsp_recorder
nohup node server.js &

echo "部署完成！请访问 http://<服务器IP>:3000 来使用多路 RTSP 录制服务。"
