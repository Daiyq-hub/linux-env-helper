# 🐧 LinuxEnv Helper (leh)

面向国内网络环境的 Ubuntu / Debian 服务器一键配置工具，支持**交互式菜单**与**命令行模式**两种方式，开箱即用。适合新 VPS 快速初始化、安全加固以及部署常用安全/靶场环境。

> 仅需 root 或 sudo 权限，脚本会自动备份所有被修改的系统配置，可放心使用。

---

## ✨ 功能特性

| 类别 | 说明 |
| --- | --- |
| 🧰 基础环境 | 时区 / DNS / SSH / APT 国内源一键切换 |
| ☕ 开发环境 | JDK（Oracle / OpenJDK，免密钥安装）、Miniconda3 + conda / pip 国内源 |
| 🐳 容器化 | Docker + Compose 安装、多镜像加速自动检测、智能拉取 |
| 📊 监控运维 | htop / btop / ncdu / glances / sysstat 一键安装，Glances Web 面板 |
| 🛡️ 安全加固 | fail2ban、SSH 端口修改、禁用密码登录（带防锁死检查） |
| ⚡ 性能优化 | BBR 拥塞控制、网络 / 文件描述符调优 |
| ℹ️ 系统信息 | 一键查看 OS / CPU / 内存 / 磁盘 / 网络 / 已装工具 / 容器 / 端口 |
| 🎯 靶场与工具 | ARL 灯塔 / Empire / Metasploit / Vulfocus / Viper 等 16 个安全模块 |

## 🚀 快速开始

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
sudo bash main.sh --info     # 查看系统环境信息
sudo bash main.sh --update   # 检查并更新脚本到最新版
sudo bash main.sh --quick    # 一键快速初始化（时区/基础工具/Docker/Miniconda3）
sudo bash main.sh --help     # 显示帮助
```

## 🖥️ 界面预览

```text
  ╔══════════════════════════════════════════════════════╗
  ║              🐧 LinuxEnv Helper v2.2.1                ║
  ║              适用于 Ubuntu / Debian 服务器             ║
  ║        交互式菜单 · 一键配置 · 命令行模式              ║
  ╚══════════════════════════════════════════════════════╝

  功能模块
  ────────────────────────────────────────────────────────
  [01] 配置APT源          [02] 基础配置
  [03] 配置Docker        [04] 查看系统信息
  [05] 配置JDK           [06] 更新脚本
  ...
  ↳ 主菜单                     [q] 退出
```

## 📂 模块一览

### 基础环境 `modules/base/`

| 模块 | 说明 |
| --- | --- |
| 配置APT源 | 自动测速 / 阿里云 / 腾讯云 / 华为云 / 清华 / 中科大 / 官方源，含备份管理 |
| 基础配置 | 启用 Root / SSH / DNS 配置 / 查看网络 / 解除 53 端口占用 |
| 配置Docker | 安装 + Compose + 镜像加速（自动测速）+ 网络代理 |
| 查看系统信息 | OS / CPU / 内存 / 磁盘 / IP / 工具 / 容器 / 端口 一览 |
| 配置JDK | OracleJDK（免密钥镜像/官网）、OpenJDK、切换、删除 |
| 配置Miniconda3 | 安装 / 卸载 / conda / pip 软件源 |
| 配置OhMyZsh | 安装 / 主题 / 插件（Gitee 加速镜像） |
| 更新脚本 | 检查并更新到最新版（Git 优先，压缩包回退） |

### 安全与运维 `modules/sec/`

| 模块 | 说明 |
| --- | --- |
| 系统优化 | 时区 / BBR 性能优化 / SSH 安全加固（fail2ban、改端口、禁用密码登录） |
| 监控工具 | htop / btop / ncdu / glances / sysstat + Glances Web 面板 |

### 靶场与安全工具 `modules/labs/`

| 模块 | 说明 |
| --- | --- |
| ARL 灯塔 | 资产侦察灯塔（Docker 部署，Web 端 https://IP:5003） |
| Empire | 渗透测试框架（v6，Web 客户端 Starkiller + REST API） |
| Metasploit | 渗透测试框架 |
| Viper | 图形化渗透平台 |
| Vulfocus | 漏洞集成平台 |
| CTFd | CTF 竞赛平台 |
| HFish | 蜜罐系统 |
| BeEF | 浏览器渗透框架 |
| Dnscat2 | DNS 隧道 |
| BlueLotus | XSS 平台 |
| AWVS | Web 漏洞扫描器 |
| OCR-API | OCR 识别服务 |
| crAPI | 现代 API 靶场 |
| XingRin | XingRin 平台 |
| DeepAudit | 深度审计 |
| ScopeSentry | 资产测绘 |

### 快捷入口

| 操作 | 说明 |
| --- | --- |
| 一键快速初始化 | 时区 + 基础工具 + Docker + Miniconda3 一条命令搞定 |

## 📁 目录结构

```text
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

## ❓ 常见问题

**Q: 运行 `leh` 提示命令不存在？**

A: 安装脚本创建的是 `/usr/local/bin/leh`，新开终端即可生效；或重新执行 `sudo bash install.sh`。

**Q: 脚本在非交互环境（如 SSH 执行、重定向日志）下运行会怎样？**

A: 已做防护：检测到 stdin 不是终端时会立即退出并提示，不会陷入菜单死循环。交互式输入遇到 EOF 也会安全退出。

**Q: 安装 JDK 需要密钥吗？**

A: 不需要。选择「公共镜像/官网（免密钥）」即可安装 Oracle JDK 8 / 11 / 17 / 21 / 22 / 23。

**Q: 换源或安装软件很慢 / 失败？**

A: 国内网络下优先选择腾讯云 / 阿里云镜像；Docker 镜像加速会自动测速挑选可用源。换源前脚本会自动备份原配置。

**Q: Docker 命令需要 sudo？**

A: 安装脚本已将当前用户加入 docker 组，重新登录后生效（或执行 `newgrp docker`）。

**Q: BBR 没生效？**

A: 执行后一般立即生效，可用 `sysctl -n net.ipv4.tcp_congestion_control` 查看（应输出 bbr）；如未生效可重启服务器。

**Q: Empire 为什么没有终端客户端？**

A: 当前部署的是 Empire v6，官方已移除 CLI 客户端，Web 端 Starkiller（http://IP:1337）就是官方客户端；终端可用 REST API（`POST /token` 登录，`/api/v2/*` 查询）。

## ⚠️ 安全提示

- 脚本需要 root / sudo 权限，运行前建议先通读代码；
- 「SSH 安全加固」中修改端口 / 禁用密码登录可能导致断连，请确保有备用登录方式；
- 所有系统配置修改都会自动备份（如 `/etc/apt/sources.list.bak.*`、`/etc/sysctl.d/99-envhelper.conf` 等）；
- 靶场/工具模块仅用于授权测试环境，请遵守当地法律法规。

## 📄 License

Apache License 2.0，详见 [LICENSE](LICENSE)。
