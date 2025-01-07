# Rtsp-Reconding-server
用于录制RTSP流的服务，可升级成为服务器，最大录制32路
可以选择录制的分辨率
安装依赖：
sudo apt update
sudo apt install ffmpeg nodejs npm
npm install express

V1.1
功能说明：
录制路数选择：根据实际需要输入录制路数。
录制分辨率选择：设置录制视频的分辨率（如 1280x720）。
存储位置选择：指定视频文件的保存目录。
V1.2
每隔 30 天覆盖旧视频、文件按开始时间命名、每段视频最大 30 分钟、未停止时连续录制下一段 的功能，我将对脚本进行以下改进：
增加定期清理功能：每次启动录制时检查存储目录是否超过 30 天，超过的文件会被删除。
支持循环录制：使用 FFmpeg 的 segment 模式自动分段录制视频。
优化录制逻辑：在停止时终止当前任务，未停止时连续录制。
使用脚本进行一键部署
需要升级到root权限

输入 sudo bash install 进行运行

说明：
录制文件路径：脚本生成的视频文件会保存在 /opt/rtsp_recorder 目录下。
服务管理：
启动服务：sudo systemctl start rtsp_recorder
停止服务：sudo systemctl stop rtsp_recorder
查看日志：sudo journalctl -u rtsp_recorder

安装与运行：

打开浏览器访问 http://localhost:3000。
