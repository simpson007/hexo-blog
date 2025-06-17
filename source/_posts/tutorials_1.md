---
title: 将Hexo部署到腾讯云服务器
date: 2022-06-18
updated: 2022-06-18
categories: 学海拾贝集
keywords: 学海拾贝集
top_img: /img/tutorials/tutorials-bg.png
cover: /img/tutorials/tutorials-cover.png
---

### 背景
一直以来，我都把博客托管在GitHub Pages上，虽然简单方便，但国内访问速度不理想，尤其是图片经常加载不出来，体验非常糟糕。于是，我决定把博客部署到自己的服务器上，不仅能大幅提升访问速度，还能根据自己的喜好调整页面风格。经过对比，我最终选择了Hexo这个静态博客框架，再加上腾讯云的轻量应用服务器，性价比和稳定性都不错。

## 一、环境准备

### 1.1 相关信息
- **电脑信息**: Apple M1 Pro
- **服务器信息**: 腾讯云轻量应用服务器
- **操作系统**: CentOS 7.6 64bit

## 二、服务端操作

### 2.1 安装Git和Nginx

```bash
sudo apt update
sudo apt install git nginx -y
```

### 2.2 创建Git用户

```bash
# 创建git用户
sudo adduser git
# 为git用户设置密码
sudo passwd git

# 配置git用户的sudo权限
sudo chmod 740 /etc/sudoers
sudo vim /etc/sudoers
# 添加如下行到root ALL=(ALL) ALL 之后
git ALL=(ALL) ALL

# 修改sudoers文件权限
sudo chmod 400 /etc/sudoers
```

### 2.3 添加SSH密钥

```bash
# 切换到git用户
su git
# 创建.ssh目录和密钥文件
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# 将本地生成的公钥粘贴到authorized_keys文件中
vim ~/.ssh/authorized_keys
```

### 2.4 创建Git仓库并实现自动部署

```bash
# 创建git仓库目录
sudo mkdir -p /var/repo
# 创建Hexo网站的根目录
sudo mkdir -p /var/www/hexo

# 切换到/var/repo目录并初始化git仓库
cd /var/repo/
sudo git init --bare blog.git

# 配置post-update钩子，自动部署代码
sudo vim /var/repo/blog.git/hooks/post-update
```

post-update文件内容：

```bash
#!/bin/bash
git --work-tree=/var/www/hexo --git-dir=/var/repo/blog.git checkout -f
```

```bash
# 赋予执行权限
sudo chmod +x /var/repo/blog.git/hooks/post-update

# 授权git用户对仓库和网站目录的访问权限
sudo chown -R git:git /var/repo /var/www/hexo
```

### 2.5 配置Nginx

```bash
# 切换到Nginx的配置文件目录
cd /etc/nginx/conf.d/
sudo vim blog.conf
```

blog.conf文件内容：

```bash
server {
    listen 80;
    server_name yourdomain.com;
    root /var/www/hexo;
    index index.html;
}
```

```bash
# 检查Nginx配置并启动服务
sudo nginx -t
sudo systemctl start nginx
sudo systemctl status nginx
```

### 2.6 修改Git用户Shell环境

```bash
# 修改git用户的默认shell为git-shell，限制登录权限
sudo vim /etc/passwd
# 将最后一行的/bin/bash改为/usr/bin/git-shell
```

## 三、本地配置（Mac）
### 3.1 安装Git

使用Xcode命令行工具安装git

```bash
xcode-select --install
git --version
```

### 3.2 安装Node.js和npm

使用Homebrew安装：

```bash
brew install node
```
### 3.3 安装Hexo及相关插件

```bash
sudo npm install hexo-cli hexo-server hexo-deployer-git -g
```

### 3.4 本地初始化博客站点
```bash
hexo init ~/blog
cd ~/blog
npm install
```

### 3.5 配置Hexo的部署信息

修改_config.yml文件：

```bash
deploy:
  type: git
  repo: git@yourserver:/var/repo/blog.git
  branch: master
```

### 3.6 部署Hexo到服务器

```bash
hexo clean
hexo generate
hexo deploy
```

## 四、测试

在浏览器中输入服务器的IP地址或域名，测试博客是否正常访问。