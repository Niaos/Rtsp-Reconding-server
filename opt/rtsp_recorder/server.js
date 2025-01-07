const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const app = express();
const PORT = 3000;

let loginIp = 'localhost';
let loginPort = 3000;

// 更新登录IP和端口的API
app.post('/api/config', (req, res) => {
    const { ip, port } = req.body;
    loginIp = ip;
    loginPort = port;
    res.status(200).json({ message: '配置已更新' });
});

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('WWW/rtsp_recorder')); 
// 提供静态文件

// 示例数据
let streams = [
    { name: 'Stream 1', recordings: ['recording1.mp4', 'recording2.mp4'] },
    { name: 'Stream 2', recordings: ['recording3.mp4'] },
];

// 获取流信息
app.get('/api/streams', (req, res) => {
    res.json(streams);
});

// 添加流
app.post('/api/streams', (req, res) => {
    const { name, recordings } = req.body;
    streams.push({ name, recordings });
    res.status(201).json({ message: 'Stream added successfully' });
});

// 删除流
app.delete('/api/streams/:name', (req, res) => {
    streams = streams.filter(stream => stream.name !== req.params.name);
    res.status(200).json({ message: 'Stream deleted successfully' });
});

// 登录验证（示例）
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (username === 'admin' && password === 'admin') {
        res.status(200).json({ message: '登录成功' });
    } else {
        res.status(401).json({ message: '用户名或密码错误' });
    }
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
