# 🚀 Hexo 博客 Docker 部署指南

本指南将帮助你将 Hexo 博客部署到腾讯云服务器，使用 Docker 容器化部署，并配置 SSL 证书。

## 📋 前置要求

### 本地环境
- Git
- Node.js 和 npm
- SSH 客户端

### 服务器要求
- 腾讯云服务器（Ubuntu 20.04 或更高版本推荐）
- 至少 1GB RAM
- 公网 IP 地址
- 域名（已解析到服务器 IP）

## 🏗️ 项目结构

```
hexo-blog/
├── source/              # Hexo 源文件
├── themes/              # 主题文件
├── public/              # 生成的静态文件
├── _config.yml          # Hexo 配置
├── package.json         # Node.js 依赖
├── Dockerfile           # Docker 镜像配置
├── docker-compose.yml   # Docker Compose 配置
├── nginx.conf           # Nginx 主配置
├── default.conf         # Nginx 站点配置
├── deploy.sh            # 本地部署脚本
├── server-init.sh       # 服务器初始化脚本
├── setup-ssl.sh         # SSL 证书配置脚本
└── ssl/                 # SSL 证书目录
    ├── fullchain.pem
    └── privkey.pem
```

## 🎯 快速开始

### 步骤 1: 准备本地项目

1. **初始化 Git 仓库**（如果还没有）
```bash
cd /path/to/your/hexo-blog
git init
git add .
git commit -m "Initial commit"
```

2. **创建 GitHub 仓库并推送**
```bash
git remote add origin https://github.com/yourusername/hexo-blog.git
git push -u origin main
```

3. **修改配置文件**

编辑 `deploy.sh`，修改服务器信息：
```bash
SERVER_USER="root"
SERVER_HOST="your-server-ip"  # 替换为你的服务器 IP
```

编辑 `server-init.sh`，修改仓库地址：
```bash
GITHUB_REPO="https://github.com/yourusername/hexo-blog.git"
```

### 步骤 2: 服务器初始化

1. **SSH 登录到服务器**
```bash
ssh root@your-server-ip
```

2. **下载并运行初始化脚本**
```bash
# 创建项目目录
mkdir -p /opt/hexo-blog
cd /opt/hexo-blog

# 下载初始化脚本
curl -O https://raw.githubusercontent.com/yourusername/hexo-blog/main/server-init.sh
chmod +x server-init.sh

# 运行初始化
./server-init.sh
```

这个脚本会自动：
- 安装 Docker 和 Docker Compose
- 安装必要的工具
- 配置防火墙
- 克隆项目代码
- 配置 SSL 证书
- 启动博客服务

### 步骤 3: 配置 SSL 证书

如果初始化时跳过了 SSL 配置，运行：
```bash
cd /opt/hexo-blog
./setup-ssl.sh
```

**注意**：运行前确保域名已解析到服务器 IP。

### 步骤 4: 日常部署

在本地开发完成后，使用部署脚本一键部署：

```bash
# 在本地项目目录
chmod +x deploy.sh
./deploy.sh "更新博客内容"
```

部署脚本会自动：
1. 生成静态文件
2. 提交代码到 Git
3. 推送到 GitHub
4. 在服务器上拉取最新代码
5. 重新构建 Docker 镜像
6. 重启服务

## 🔧 常用命令

### 本地命令

```bash
# 清理缓存
npm run clean

# 生成静态文件
npm run build

# 本地预览
npm run server

# 一键部署
./deploy.sh "提交信息"
```

### 服务器命令

```bash
# 进入项目目录
cd /opt/hexo-blog

# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 启动服务
docker compose up -d

# 重新构建
docker compose up -d --build

# 查看 Nginx 访问日志
tail -f logs/nginx/access.log

# 查看 Nginx 错误日志
tail -f logs/nginx/error.log
```

## 🔐 SSL 证书管理

### 手动更新证书
```bash
certbot renew
cp /etc/letsencrypt/live/yushenjian.com/*.pem /opt/hexo-blog/ssl/
cd /opt/hexo-blog
docker compose restart
```

### 查看证书状态
```bash
certbot certificates
```

### 测试自动续期
```bash
certbot renew --dry-run
```

## 📊 监控和维护

### 健康检查
```bash
# 检查网站是否正常
curl -I https://yushenjian.com

# 检查 Docker 资源使用
docker stats

# 检查磁盘空间
df -h

# 清理 Docker 资源
docker system prune -a
```

### 备份

1. **备份源码**（已通过 Git 管理）
2. **备份 SSL 证书**
```bash
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz /opt/hexo-blog/ssl/
```

## 🐛 故障排查

### 网站无法访问

1. **检查容器状态**
```bash
docker compose ps
```

2. **查看容器日志**
```bash
docker compose logs
```

3. **检查端口**
```bash
netstat -tlnp | grep -E "80|443"
```

4. **检查防火墙**
```bash
ufw status
```

### SSL 证书问题

1. **证书过期**
```bash
certbot renew --force-renewal
```

2. **证书文件权限**
```bash
chmod 644 ssl/fullchain.pem
chmod 600 ssl/privkey.pem
```

### Docker 问题

1. **重启 Docker 服务**
```bash
systemctl restart docker
```

2. **清理并重建**
```bash
docker compose down
docker system prune -a
docker compose up -d --build
```

## 📝 配置说明

### Dockerfile 说明
- 使用多阶段构建减小镜像体积
- 第一阶段：Node.js 环境构建 Hexo
- 第二阶段：Nginx 服务静态文件

### docker-compose.yml 说明
- 挂载 SSL 证书目录
- 挂载日志目录
- 配置健康检查
- 自动重启策略

### Nginx 配置说明
- HTTP 自动重定向到 HTTPS
- 启用 HTTP/2
- 配置 SSL 安全选项
- 启用 Gzip 压缩
- 设置缓存策略
- 安全头部配置

## 🔄 更新和升级

### 更新 Hexo 主题
```bash
# 本地更新主题
cd themes/butterfly
git pull

# 重新部署
./deploy.sh "更新主题"
```

### 更新 Node.js 依赖
```bash
# 本地更新
npm update

# 重新部署
./deploy.sh "更新依赖"
```

### 更新 Docker 镜像
```bash
# 服务器端
docker pull nginx:alpine
docker compose up -d --build
```

## 📞 获取帮助

- Hexo 官方文档：https://hexo.io/zh-cn/docs/
- Docker 文档：https://docs.docker.com/
- Nginx 文档：https://nginx.org/en/docs/

## 📄 许可证

本部署方案基于 MIT 许可证。

---

**提示**：记得定期备份数据和更新系统安全补丁！