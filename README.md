# 🐧 LinuxEnv Helper (leh)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%2F%20Debian-orange.svg)]()
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)]()

面向**国内网络环境**的 Ubuntu / Debian 服务器一键配置工具，支持交互式菜单与命令行两种模式，开箱即用。

## ✨ 功能特性

| 类别 | 说明 |
|------|------|
| 🧰 基础环境 | 时区 / DNS / SSH / APT 国内源一键切换 |
| ☕ 开发环境 | JDK（Oracle / OpenJDK，免密钥安装）、Miniconda3 + conda / pip 国内源 |
| 🐳 容器化 | Docker + Compose 安装、多镜像加速自动检测 |
| 📊 监控运维 | htop / btop / ncdu / glances / sysstat 一键安装，Glances Web 面板 |
| 🛡️ 安全加固 | fail2ban、SSH 端口修改、禁用密码登录（带防锁死检查） |
| ⚡ 性能优化 | BBR 拥塞控制、网络 / 文件描述符调优 |
| 🎯 靶场与工具 | Vulfocus / CTFd / ARL / Metasploit / BeEF 等 16 个安全模块 |

## 📦 安装与使用

### 方式一：一键安装（推荐）

```bash
git clone https://github.com/Daiyq-hub/linux-env-helper.git
cd linux-env-helper
sudo bash install.sh      # 注册全局命令 leh
leh                       # 任意目录启动
```

### 方式二：不安装直接运行

```bash
sudo bash main.sh         # 交互式菜单
sudo bash bin/leh         # 或通过仓库内启动器
```

### 命令行模式（非交互）

```bash
sudo bash main.sh --list     # 列出全部模块
sudo bash main.sh --quick    # 一键快速初始化（时区/基础工具/Docker/Miniconda3）
sudo bash main.sh --help     # 显示帮助
```

### 首次运行流程

1. 预检查会询问「是否配置 APT 镜像源」——国内服务器建议输入 `y`，再选择腾讯云 / 阿里云 / 清华 / 中科大；
2. 「是否检查项目更新」按 `n` 跳过即可（GitHub 直连可能较慢）；
3. 按任意键进入主菜单，输入序号选择模块。

## 📂 模块目录

### 基础环境 `modules/base/`

| # | 模块 | 说明 |
|---|------|------|
| 1 | 基础配置 | Root / SSH / DNS 等基础项 |
| 2 | 配置APT源 | 腾讯 / 阿里 / 清华 / 中科大 / 官方 |
| 3 | 配置JDK | OracleJDK（免密钥镜像/官网）、OpenJDK、切换、删除 |
| 4 | 配置Miniconda3 | 安装 / 卸载 / 软件源 |
| 5 | 配置Docker | 安装 + Compose + 镜像加速（自动测速） |
| 6 | 配置OhMyZsh | Zsh 增强（Gitee 镜像） |

### 安全与运维 `modules/sec/`

| # | 模块 | 说明 |
|---|------|------|
| 7 | 系统优化 | 时区 / BBR 性能优化 / SSH 安全加固 |
| 8 | 监控工具 | htop / btop / ncdu / glances / sysstat + Glances Web |

### 靶场与安全工具 `modules/labs/`

| # | 模块 | 说明 |
|---|------|------|
| 9 | 配置Vulfocus | 漏洞集成平台 |
| 10 | 配置ARL灯塔 | 资产侦察灯塔 |
| 11 | 配置Metasploit | 渗透测试框架 |
| 12 | 配置Viper | 图形化渗透平台 |
| 13 | 配置Empire | 后渗透框架 |
| 14 | 配置Dnscat2 | DNS 隧道 |
| 15 | 配置BeEF | 浏览器渗透框架 |
| 16 | 配置BlueLotus | XSS 平台 |
| 17 | 配置HFish | 蜜罐系统 |
| 18 | 配置CTFd | CTF 竞赛平台 |
| 19 | 配置AWVS | Web 漏洞扫描器 |
| 20 | 配置OCR-API | OCR 识别服务 |
| 21 | 配置crAPI | 现代 API 靶场 |
| 22 | 配置XingRin | XingRin 平台 |
| 23 | 配置DeepAudit | 深度审计 |
| 24 | 配置ScopeSentry | 资产测绘 |

### 快捷入口

| 操作 | 说明 |
|------|------|
| 25 | 一键快速初始化 | 时区 + 基础工具 + Docker + Miniconda3 |

## 📁 目录结构

```
linux-env-helper/
├── bin/
│   └── leh               # 仓库内启动器（无需安装）
├── install.sh            # 一键安装，注册 leh 全局命令
├── main.sh               # 主入口（交互菜单 + CLI 模式）
├── lib/                  # 公共函数库
│   ├── core.sh           # 全局状态与环境检测
│   ├── ui.sh             # 颜色 / 消息 / 菜单 / 输入交互
│   ├── util.sh           # 备份 / 下载 / 包管理 / 服务 / Docker 辅助
│   └── net.sh            # 网络检测 / 镜像测速 / 项目更新
├── modules/              # 业务模块（按类目组织，自动注册到主菜单）
│   ├── base/             # 基础环境
│   ├── sec/              # 安全与运维
│   └── labs/             # 靶场与安全工具
└── LICENSE               # Apache License 2.0
```

## 🚀 项目特色

- 新增「系统优化」模块：时区设置、BBR 内核参数优化、SSH 安全加固（fail2ban / 改端口 / 禁用密码登录，带防锁死检查）
- 新增「监控工具」模块：监控套件一键安装 + Glances Web 面板
- 支持命令行模式：`--list` / `--quick` / `--help`，方便脚本化与自动化
- 一键快速初始化：时区 + 基础工具 + Docker + Miniconda3 一条命令搞定
- JDK 免密钥安装：JDK 8 走华为云镜像，11 / 17 / 21 / 22 / 23 走 Oracle 官网 NFTC 下载
- Docker 镜像加速自动测速，从多个国内源中挑选可用项
- 全局命令 `leh`，安装后可在任意目录直接使用
- 仓库仅包含代码与文档，无冗余素材

## ❓ 常见问题

**Q: 运行 `leh` 提示命令不存在？**

A: 安装脚本创建的是 `/usr/local/bin/leh`，新开终端即可生效；或重新执行 `sudo bash install.sh`。

**Q: 安装 JDK 需要密钥吗？**

A: 不需要。选择「公共镜像/官网（免密钥）」即可安装 Oracle JDK 8 / 11 / 17 / 21 / 22 / 23。

**Q: 换源或安装软件很慢 / 失败？**

A: 国内网络下优先选择腾讯云 / 阿里云镜像；Docker 镜像加速会自动测速挑选可用源。换源前脚本会自动备份原配置。

**Q: Docker 命令需要 sudo？**

A: 安装脚本已将当前用户加入 docker 组，重新登录后生效（或执行 `newgrp docker`）。

**Q: BBR 没生效？**

A: 执行后一般立即生效，可用 `sysctl -n net.ipv4.tcp_congestion_control` 查看（应输出 `bbr`）；如未生效可重启服务器。

## ⚠️ 安全提示

- 脚本需要 root / sudo 权限，运行前建议先通读代码
- 「SSH 安全加固」中修改端口 / 禁用密码登录可能导致断连，请确保有备用登录方式
- 所有系统配置修改都会自动备份（如 `/etc/apt/sources.list.bak.*`、`/etc/sysctl.d/99-envhelper.conf` 等）

## 🤝 贡献与反馈

欢迎提交 [Issue](https://github.com/Daiyq-hub/linux-env-helper/issues) 或 Pull Request。

## 📄 License

Apache License 2.0，详见 [LICENSE](LICENSE) 文件。
