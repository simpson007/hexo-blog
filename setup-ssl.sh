#!/bin/bash

# ==============================================
# SSL 证书配置脚本
# 用于配置 Let's Encrypt SSL 证书
# ==============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
DOMAIN="yushenjian.com"
WWW_DOMAIN="www.yushenjian.com"
EMAIL="13951719485@163.com"

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

print_step "安装 Certbot"

# 检查系统类型并安装 certbot
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    apt-get update
    apt-get install -y certbot
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL
    yum install -y epel-release
    yum install -y certbot
else
    print_error "不支持的操作系统"
    exit 1
fi

print_success "Certbot 安装完成"

print_step "生成 SSL 证书"

# 停止可能占用 80 端口的服务
print_info "停止 Docker 服务（如果正在运行）"
docker compose down 2>/dev/null || true

# 生成证书
certbot certonly --standalone \
    -d $DOMAIN \
    -d $WWW_DOMAIN \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    --expand

if [ $? -eq 0 ]; then
    print_success "SSL 证书生成成功"
else
    print_error "SSL 证书生成失败"
    exit 1
fi

print_step "配置证书目录"

# 创建 SSL 目录
mkdir -p ./ssl

# 复制证书文件
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./ssl/
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./ssl/

# 设置权限
chmod 644 ./ssl/fullchain.pem
chmod 600 ./ssl/privkey.pem

print_success "证书文件已复制到 ./ssl 目录"

print_step "创建自动续期脚本"

# 创建续期脚本
cat > /etc/cron.monthly/renew-ssl.sh <<EOF
#!/bin/bash
certbot renew --quiet --pre-hook "cd /opt/hexo-blog && docker compose down" --post-hook "cd /opt/hexo-blog && docker compose up -d"
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/hexo-blog/ssl/
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/hexo-blog/ssl/
EOF

chmod +x /etc/cron.monthly/renew-ssl.sh

print_success "自动续期脚本已创建"

print_step "✅ SSL 证书配置完成"

echo ""
print_info "证书信息："
print_info "域名: $DOMAIN, $WWW_DOMAIN"
print_info "证书路径: ./ssl/"
print_info "自动续期: 每月自动检查并续期"
echo ""
print_info "现在可以运行 docker compose up -d 启动博客服务"