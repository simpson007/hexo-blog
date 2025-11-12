#!/bin/bash

# ========================================
# Hexo 博客一键部署脚本（本地端）
# ========================================
# 使用方法: ./deploy.sh [commit_message]
# 示例: ./deploy.sh "更新博客内容"
# ========================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量 - 请根据实际情况修改
SERVER_USER="root"
SERVER_HOST="your-server-ip"  # 请修改为你的腾讯云服务器IP
SERVER_PATH="/opt/hexo-blog"
GIT_BRANCH="main"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
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

# 检查是否在项目根目录
if [ ! -f "package.json" ] || [ ! -f "_config.yml" ]; then
    print_error "错误：请在 Hexo 项目根目录运行此脚本"
    exit 1
fi

# 获取提交消息
COMMIT_MSG="${1:-'更新博客内容'}"

print_step "1. 检查 Git 状态"
if ! git status &> /dev/null; then
    print_error "错误：当前目录不是 Git 仓库"
    print_info "请先初始化 Git 仓库: git init"
    exit 1
fi

# 显示当前分支
CURRENT_BRANCH=$(git branch --show-current)
print_info "当前分支: ${CURRENT_BRANCH}"

print_step "2. 清理和生成静态文件"
print_info "清理旧文件..."
npm run clean
print_success "清理完成"

print_info "生成新的静态文件..."
npm run build
print_success "静态文件生成完成"

# 检查是否有未提交的更改
if [[ -n $(git status -s) ]]; then
    print_step "3. 提交到 Git"

    print_info "添加文件到暂存区..."
    git add .

    print_info "提交更改..."
    git commit -m "$COMMIT_MSG"
    print_success "提交成功: $COMMIT_MSG"
else
    print_info "没有需要提交的更改"
fi

print_step "4. 推送到远程仓库"
# 检查是否配置了远程仓库
if ! git remote get-url origin &> /dev/null; then
    print_warning "未配置远程仓库"
    print_info "请先配置远程仓库:"
    echo "  git remote add origin https://github.com/yourusername/hexo-blog.git"
    echo ""
    read -p "是否跳过推送步骤？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SKIP_PUSH=true
else
    print_info "推送到远程分支: ${CURRENT_BRANCH}"
    git push origin ${CURRENT_BRANCH}
    print_success "推送成功"
    SKIP_PUSH=false
fi

print_step "5. 部署到服务器"
print_info "连接到: ${SERVER_USER}@${SERVER_HOST}"

# 检查服务器连接
if ! ssh -o ConnectTimeout=5 ${SERVER_USER}@${SERVER_HOST} "echo 'Connected'" &> /dev/null; then
    print_error "无法连接到服务器"
    print_info "请检查："
    print_info "1. 服务器IP地址是否正确"
    print_info "2. SSH 密钥是否配置"
    print_info "3. 网络连接是否正常"
    exit 1
fi

# 生成服务器端执行的命令
SERVER_COMMANDS=$(cat <<'EOF'
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_step() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

cd SERVER_PATH_PLACEHOLDER

print_step "服务器端部署开始"

# 检查目录是否存在
if [ ! -d ".git" ]; then
    print_error "项目目录不存在，请先在服务器上克隆项目"
    print_info "运行以下命令："
    echo "  cd /opt"
    echo "  git clone https://github.com/yourusername/hexo-blog.git"
    echo "  cd hexo-blog"
    echo "  ./setup-ssl.sh  # 配置SSL证书"
    exit 1
fi

print_step "1. 拉取最新代码"
git fetch origin
git checkout BRANCH_PLACEHOLDER
git pull origin BRANCH_PLACEHOLDER
print_success "代码拉取成功"

print_step "2. 显示最新提交"
git log -1 --pretty=format:"%h - %an, %ar : %s"
echo ""

print_step "3. 检查 Docker 服务"
if ! command -v docker &> /dev/null; then
    print_error "Docker 未安装"
    print_info "请先安装 Docker: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    print_error "Docker Compose 未安装"
    exit 1
fi

print_step "4. 停止现有容器"
docker compose down || true
print_success "容器已停止"

print_step "5. 构建新镜像"
docker compose build --no-cache
print_success "镜像构建完成"

print_step "6. 启动服务"
docker compose up -d
print_success "服务已启动"

print_step "7. 等待服务就绪"
sleep 5

print_step "8. 检查服务状态"
docker compose ps

print_step "9. 健康检查"
for i in {1..5}; do
    if curl -f -s http://localhost > /dev/null; then
        print_success "网站健康检查通过"
        break
    else
        if [ $i -eq 5 ]; then
            print_error "网站启动失败"
            print_info "查看日志:"
            docker compose logs --tail=50
            exit 1
        fi
        print_info "等待服务启动... ($i/5)"
        sleep 3
    fi
done

print_step "✅ 部署完成！"
print_success "博客已成功部署"
print_info "访问地址: https://yushenjian.com"
echo ""
EOF
)

# 替换占位符
SERVER_COMMANDS="${SERVER_COMMANDS//SERVER_PATH_PLACEHOLDER/$SERVER_PATH}"
SERVER_COMMANDS="${SERVER_COMMANDS//BRANCH_PLACEHOLDER/$CURRENT_BRANCH}"

# 执行远程命令
ssh -t ${SERVER_USER}@${SERVER_HOST} "bash -c '$SERVER_COMMANDS'"

echo ""
print_step "🎉 部署流程完成"
print_success "博客已成功部署到服务器"
print_info "访问地址: https://yushenjian.com"
print_info "查看实时日志: ssh ${SERVER_USER}@${SERVER_HOST} 'cd ${SERVER_PATH} && docker compose logs -f'"
echo ""