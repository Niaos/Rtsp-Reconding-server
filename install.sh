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

# 用户自定义参数
read -p "请输入要录制的 RTSP 路数 (默认 $DEFAULT_STREAMS): " NUM_STREAMS
read -p "请输入录制分辨率 (如 1920x1080，默认 $DEFAULT_RESOLUTION): " RESOLUTION
read -p "请输入视频存储位置 (默认 $DEFAULT_STORAGE): " STORAGE

NUM_STREAMS=${NUM_STREAMS:-$DEFAULT_STREAMS}
RESOLUTION=${RESOLUTION:-$DEFAULT_RESOLUTION}
STORAGE=${STORAGE:-$DEFAULT_STORAGE}

echo "配置参数:"
echo "录制路数: $NUM_STREAMS"
echo "录制分辨率: $RESOLUTION"
echo "存储位置: $STORAGE"

# 创建存储目录
echo "创建存储目录..."
mkdir -p "$STORAGE"
chmod 755 "$STORAGE"

# 更新系统软件包
echo "更新系统软件包..."
apt update && apt upgrade -y

# 安装 FFmpeg
echo "安装 FFmpeg..."
apt install -y ffmpeg

# 安装 Node.js 和 npm
echo "安装 Node.js 和 npm..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs

# 创建项目目录
PROJECT_DIR="/opt/rtsp_recorder"
echo "创建项目目录: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 创建后端文件
echo "创建后端文件..."
cat > server.js << EOF
const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(express.json());

const STORAGE_DIR = '${STORAGE}';
const DEFAULT_RESOLUTION = '${RESOLUTION}';
const MAX_FILE_AGE = 30 * 24 * 60 * 60 * 1000; // 30 天
const MAX_DURATION = 30 * 60; // 每段视频最大 30 分钟

const recordingTasks = {};

// 清理过期视频文件
function cleanOldFiles() {
    const now = Date.now();
    fs.readdir(STORAGE_DIR, (err, files) => {
        if (err) {
            console.error('Failed to read storage directory:', err);
            return;
        }
        files.forEach(file => {
            const filePath = path.join(STORAGE_DIR, file);
            fs.stat(filePath, (err, stats) => {
                if (err) {
                    console.error('Failed to get file stats:', err);
                    return;
                }
                if (now - stats.mtimeMs > MAX_FILE_AGE) {
                    fs.unlink(filePath, err => {
                        if (err) {
                            console.error('Failed to delete old file:', err);
                        } else {
                            console.log('Deleted old file:', file);
                        }
                    });
                }
            });
        });
    });
}

// 开始录制 RTSP 流
app.post('/start-recording', (req, res) => {
    const { rtspUrl, streamId } = req.body;

    if (!rtspUrl || !streamId) {
        return res.status(400).send('RTSP URL and Stream ID are required');
    }

    if (recordingTasks[streamId]) {
        return res.status(400).send(\`Stream \${streamId} is already being recorded.\`);
    }

    const outputFilePattern = path.join(STORAGE_DIR, \`recording_\${streamId}_%Y%m%d_%H%M%S.mp4\`);

    cleanOldFiles(); // 启动前清理旧文件

    const ffmpegCmd = [
        '-i', rtspUrl,             // 输入 RTSP URL
        '-vf', \`scale=\${DEFAULT_RESOLUTION}\`, // 设置分辨率
        '-c:v', 'libx264',         // 编码方式
        '-preset', 'ultrafast',    // 快速模式
        '-f', 'segment',           // 分段录制模式
        '-segment_time', MAX_DURATION.toString(), // 每段时长
        '-reset_timestamps', '1',  // 重置时间戳
        outputFilePattern           // 输出文件模式
    ];

    const ffmpegProcess = spawn('ffmpeg', ffmpegCmd);

    ffmpegProcess.stderr.on('data', (data) => {
        console.error(\`Stream \${streamId} FFmpeg stderr: \${data}\`);
    });

    ffmpegProcess.on('close', (code) => {
        console.log(\`Stream \${streamId} FFmpeg process exited with code \${code}\`);
        delete recordingTasks[streamId];
    });

    recordingTasks[streamId] = { rtspUrl, process: ffmpegProcess };
    res.status(200).send(\`Recording started for stream \${streamId}\`);
});

// 停止录制 RTSP 流
app.post('/stop-recording', (req, res) => {
    const { streamId } = req.body;

    if (!streamId || !recordingTasks[streamId]) {
        return res.status(400).send('Invalid Stream ID');
    }

    const ffmpegProcess = recordingTasks[streamId].process;
    ffmpegProcess.kill('SIGINT');
    res.status(200).send(\`Recording stopped for stream \${streamId}\`);
});

// 获取任务列表
app.get('/recording-tasks', (req, res) => {
    res.status(200).json(recordingTasks);
});

// 启动服务器
const PORT = 3000;
app.listen(PORT, () => {
    console.log(\`RTSP Recorder Server is running on port \${PORT}\`);
});
EOF

# 安装 Node.js 依赖
echo "安装 Node.js 依赖..."
npm install express

# 设置服务启动脚本
echo "设置服务启动脚本..."
cat > /etc/systemd/system/rtsp_recorder.service << EOF
[Unit]
Description=Multi RTSP Recorder Service
After=network.target

[Service]
ExecStart=/usr/bin/node $PROJECT_DIR/server.js
WorkingDirectory=$PROJECT_DIR
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
echo "启用并启动多路 RTSP 录制服务..."
systemctl daemon-reload
systemctl enable rtsp_recorder
systemctl start rtsp_recorder

echo "部署完成！请访问 http://<服务器IP>:3000 来使用多路 RTSP 录制服务。"
