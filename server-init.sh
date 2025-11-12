#!/bin/bash

# ========================================
# 服务器初始化脚本
# 在腾讯云服务器上首次部署时运行
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
PROJECT_PATH="/opt/hexo-blog"
GITHUB_REPO="https://github.com/yourusername/hexo-blog.git"  # 请修改为你的仓库地址
DOMAIN="yushenjian.com"

# 打印函数
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 root 用户运行此脚本"
    exit 1
fi

print_step "系统环境准备"

# 更新系统
print_info "更新系统包..."
apt-get update
apt-get upgrade -y
print_success "系统更新完成"

print_step "安装 Docker"

# 检查 Docker 是否已安装
if command -v docker &> /dev/null; then
    print_info "Docker 已安装，版本："
    docker --version
else
    print_info "安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    print_success "Docker 安装完成"
fi

# 安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_info "安装 Docker Compose..."
    apt-get install -y docker-compose-plugin
    print_success "Docker Compose 安装完成"
fi

print_step "安装必要工具"

# 安装 Git, Nginx (用于 certbot), 和其他工具
apt-get install -y git curl wget vim certbot python3-certbot-nginx

print_success "工具安装完成"

print_step "配置防火墙"

# 开放必要的端口
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp   # SSH
    ufw allow 80/tcp   # HTTP
    ufw allow 443/tcp  # HTTPS
    ufw --force enable
    print_success "防火墙配置完成"
else
    print_info "未检测到 UFW 防火墙"
fi

print_step "克隆项目"

# 创建项目目录
if [ ! -d "$PROJECT_PATH" ]; then
    print_info "克隆项目到 $PROJECT_PATH"
    cd /opt
    git clone $GITHUB_REPO hexo-blog
    cd $PROJECT_PATH
    print_success "项目克隆完成"
else
    print_info "项目目录已存在"
    cd $PROJECT_PATH
    git pull origin main
fi

print_step "创建必要的目录"

# 创建日志目录
mkdir -p logs/nginx
mkdir -p ssl

print_success "目录创建完成"

print_step "配置 SSL 证书"

print_info "生成 Let's Encrypt SSL 证书..."
print_warning "确保域名 $DOMAIN 已经解析到此服务器"

read -p "域名是否已解析到此服务器？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 临时停止占用 80 端口的服务
    systemctl stop nginx 2>/dev/null || true

    # 获取证书
    certbot certonly --standalone \
        -d $DOMAIN \
        -d www.$DOMAIN \
        --non-interactive \
        --agree-tos \
        --email admin@$DOMAIN

    # 复制证书
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./ssl/
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./ssl/

    # 设置权限
    chmod 644 ./ssl/fullchain.pem
    chmod 600 ./ssl/privkey.pem

    print_success "SSL 证书配置完成"

    # 配置自动续期
    echo "0 0 1 * * root certbot renew --quiet && cp /etc/letsencrypt/live/$DOMAIN/*.pem $PROJECT_PATH/ssl/ && cd $PROJECT_PATH && docker compose restart" > /etc/cron.d/certbot-renew
    print_success "自动续期已配置"
else
    print_warning "跳过 SSL 配置，稍后请运行 ./setup-ssl.sh"
fi

print_step "启动服务"

# 构建和启动 Docker 容器
print_info "构建 Docker 镜像..."
docker compose build

print_info "启动容器..."
docker compose up -d

print_success "服务已启动"

# 等待服务就绪
sleep 5

# 检查服务状态
docker compose ps

print_step "验证部署"

# 健康检查
if curl -f -s http://localhost > /dev/null; then
    print_success "博客服务运行正常"
else
    print_error "博客服务启动失败"
    print_info "查看日志："
    docker compose logs
fi

print_step "✅ 初始化完成！"

echo ""
print_success "服务器初始化成功"
print_info "项目路径: $PROJECT_PATH"
print_info "访问地址: https://$DOMAIN"
echo ""
print_info "常用命令："
echo "  cd $PROJECT_PATH"
echo "  docker compose logs -f      # 查看日志"
echo "  docker compose restart      # 重启服务"
echo "  docker compose down         # 停止服务"
echo "  docker compose up -d        # 启动服务"
echo "  ./deploy.sh                 # 更新部署"
echo ""