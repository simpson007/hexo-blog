---
title: 终端下文件与目录操作指南
date: 2021-06-04
updated: 2022-08-01
categories: 学海拾贝集
keywords: 学海拾贝集
top_img: /img/tutorials/tutorials-bg.png
cover: /img/tutorials/tutorials-cover.png
---

本文总结了在终端下对文件和目录进行 **增、删、改、查** 的常用操作，并附带命令使用技巧与脚本创建方法。  
> ⚠️ 环境提示：  
> 本文命令在 **Linux / macOS / WSL 或 Git-Bash** 下验证通过；Windows **原生 CMD/PowerShell** 请留意文中特殊提示。

---

## 1. 查（查看文件与目录）

| 功能 | 命令 | 平台差异 |
|---|---|---|
| 查看当前目录绝对路径 | `pwd` | 全平台内置 |
| 查看目录内容 | `ls` / `ls path` | 全平台可用（Windows 需 Git-Bash 或 PowerShell 别名） |
| 查看文件内容 | `cat path` | 同上 |
| 查看文件前 n 行 | `head -n 10 path` | 同上 |
| 查看文件后 n 行 | `tail -n 10 path` | 同上 |
| 可滚动查看 | `less path` | Windows 原生无 `less`，需 Git-Bash |
| 详细列表 | `ls -l path` | 输出格式略有差异，功能一致 |
| 查看时间戳 | `stat path` | **Linux/macOS 专用**；Windows 原生字段不同，建议 Git-Bash 下使用或 `Get-ItemProperty` |

---

## 2. 增（创建、复制）

| 功能 | 命令 | 平台差异 |
|---|---|---|
| 创建空文件 | `touch file` | Windows 原生无 `touch`，可用 `type nul >file`（CMD）或 `ni file`（PowerShell） |
| 覆盖写入 | `echo hello > file` | Windows 可能带 BOM/CRLF，推荐 `printf "hello\n" > file` |
| 追加写入 | `echo world >> file` | 同上 |
| 创建多级目录 | `mkdir -p a/b/c` | 全平台 ≥Win10 |
| 复制文件 | `cp 1.txt 2.txt` | 全平台 |
| 复制目录 | `cp -r dir1 dir2` | 不会复制符号链接目标/NTFS 流；Linux 用 `cp -a`，macOS 用 `cp -R`，Windows 用 `robocopy /e /copyall` |

---

## 3. 删（删除文件和目录）

| 功能 | 命令 | 平台差异 |
|---|---|---|
| 删除文件 | `rm file` | Windows 原生用 `del file` |
| 删除目录 | `rm -rf dir` | Windows 原生用 `rmdir /s /q dir` |
| 危险警告 | ⚠️ `rm -rf` 不可逆，确认路径再回车！ | 全平台通用 |

---

## 4. 改（编辑、重命名、移动）

| 功能 | 命令 | 平台差异 |
|---|---|---|
| 命令行编辑 | `nano file` | Linux/macOS 自带；Windows 需额外安装 |
| 图形编辑 | `code file` | 需把 VS Code 的「Shell Command」安装到 PATH |
| Windows 默认程序 | `start file` | Windows 独有；Linux 用 `xdg-open`，macOS 用 `open` |
| 清空文件 | `> file` | 全平台支持 |
| 重命名/移动 | `mv old new` / `mv file dir/` | 全平台一致 |
| 更新时间戳 | `touch file` | 同「创建空文件」行 |

---

## 5. 查看命令帮助与返回值

| 功能 | 命令 | 平台差异 |
|---|---|---|
| 内置帮助 | `ls --help \| less` | Windows 原生无 `less`，可用 `more` 或 Git-Bash |
| 简化教程 | `tldr ls` | 安装方式：<br>Linux/macOS: `sudo npm i -g tldr` / `brew install tldr`<br>Windows: `scoop install tldr` 或 `npm i -g tldr` |
| 上个命令返回值 | `echo $?` | **CMD 用 `echo %errorlevel%`**<br>**PowerShell 用 `echo $LASTEXITCODE`** |

---

## 6. 命令合并

| 功能 | 命令 | 平台差异 |
|---|---|---|
| 成功才继续 | `cmd1 && cmd2` | CMD/PowerShell 均支持 |
| 无论成败继续 | `cmd1; cmd2` | **CMD 不支持分号**，PowerShell 支持 |

---

## 7. 创建脚本

### 7.1 脚本示例（跨平台 Bash）

```bash
#!/usr/bin/env bash
# 创建项目目录并写入基础文件
if [ -z "$1" ]; then
  echo "请提供目录名参数"
  exit 1
fi
mkdir -p "$1" && cd "$1" || exit
touch index.html style.css main.js
printf "<!DOCTYPE html>\n<h1>title</h1>\n" > index.html
```

### 7.2 运行方式

| 系统 | 步骤 |
|---|---|
| Linux/macOS/WSL | `chmod +x script.sh && ./script.sh myproject` |
| Windows Git-Bash | 同上 |
| Windows 原生 | **无需 chmod**；直接 `bash script.sh myproject` |

### 7.3 把脚本目录加入 PATH

| 系统 | 操作 |
|---|---|
| Linux/macOS/WSL | `echo 'export PATH=$PATH:/path/to/script' >> ~/.bashrc` |
| Windows CMD | `setx PATH "%PATH%;C:\path\to\script"` |
| Windows PowerShell | `$env:PATH += ';C:\path\to\script'`（或图形界面「系统属性→环境变量」） |

---