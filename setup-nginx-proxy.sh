#!/bin/bash

# ==============================================
# 配置 Nginx 反向代理脚本
# 用于同时运行 AIGE 和 Hexo 两个项目
# ==============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 root 用户运行此脚本"
    exit 1
fi

print_step "1. 停止现有的 Docker 服务"

# 停止 Hexo 博客
cd /opt/hexo-blog
docker compose down

# 停止 AIGE 项目
cd /opt/AIGE
docker compose down

print_success "Docker 服务已停止"

print_step "2. 修改 Hexo 博客配置"

cd /opt/hexo-blog
# 使用新的配置文件
if [ -f docker-compose-internal.yml ]; then
    mv docker-compose.yml docker-compose.yml.bak
    cp docker-compose-internal.yml docker-compose.yml
    print_success "Hexo 博客配置已更新（使用 8080 端口）"
fi

print_step "3. 启动项目服务"

# 启动 AIGE
print_info "启动 AIGE 项目..."
cd /opt/AIGE
docker compose up -d
sleep 5

# 启动 Hexo
print_info "启动 Hexo 博客..."
cd /opt/hexo-blog
docker compose up -d
sleep 5

print_success "项目服务已启动"

print_step "4. 安装并配置 Nginx"

# 安装 Nginx
apt-get update
apt-get install -y nginx

# 备份原有配置
if [ -f /etc/nginx/sites-enabled/default ]; then
    mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak
fi

# 复制新配置
cp /opt/hexo-blog/nginx-proxy.conf /etc/nginx/sites-available/multi-projects
ln -sf /etc/nginx/sites-available/multi-projects /etc/nginx/sites-enabled/

print_success "Nginx 配置已更新"

print_step "5. 申请 games.yushenjian.com 的 SSL 证书"

print_info "为 games.yushenjian.com 申请 SSL 证书..."
certbot certonly --nginx \
    -d games.yushenjian.com \
    --non-interactive \
    --agree-tos \
    --email 13951719485@163.com \
    || print_warning "games.yushenjian.com 证书申请失败，请手动处理"

print_step "6. 重启 Nginx"

# 测试配置
nginx -t

# 重启 Nginx
systemctl restart nginx
systemctl enable nginx

print_success "Nginx 已重启"

print_step "7. 验证服务"

echo ""
print_info "检查服务状态..."
echo ""

# 检查 Docker 容器
print_info "Docker 容器状态："
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# 检查端口
print_info "端口监听状态："
netstat -tlnp | grep -E ":(80|443|3000|8080|8182) " | grep LISTEN

echo ""

# 测试访问
print_info "测试内部访问："
echo -n "AIGE 前端 (3000): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "失败"
echo ""

echo -n "AIGE 后端 (8182): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8182/health || echo "失败"
echo ""

echo -n "Hexo 博客 (8080): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "失败"
echo ""

print_step "✅ 配置完成！"

echo ""
print_success "所有服务已配置完成"
print_info "访问地址："
print_info "  博客: https://yushenjian.com"
print_info "  游戏: https://games.yushenjian.com"
echo ""
print_info "管理命令："
echo "  查看日志："
echo "    Hexo: cd /opt/hexo-blog && docker compose logs -f"
echo "    AIGE: cd /opt/AIGE && docker compose logs -f"
echo "    Nginx: tail -f /var/log/nginx/error.log"
echo ""
echo "  重启服务："
echo "    Hexo: cd /opt/hexo-blog && docker compose restart"
echo "    AIGE: cd /opt/AIGE && docker compose restart"
echo "    Nginx: systemctl restart nginx"
echo ""