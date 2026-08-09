# LinuxEnv Helper (leh)

面向国内网络环境的 Ubuntu/Debian 服务器一键配置工具（交互式菜单）。

本项目在 [LinuxEnvConfig](https://gitee.com/yijingsec/LinuxEnvConfig)（Apache 2.0）模块化架构基础上优化扩展而来，保留了原有 22 个模块，并新增「系统优化」模块与 JDK 免密钥安装等改进。

## 功能模块

| # | 模块 | 说明 |
|---|------|------|
| 1 | 基础配置 | Root / SSH / DNS 等基础项 |
| 2 | 配置APT源 | 腾讯 / 阿里 / 清华 / 中科大 / 官方 |
| 3 | 配置JDK | OracleJDK（免密钥镜像/官网）、OpenJDK、切换、删除 |
| 4 | 配置Miniconda3 | 安装 / 卸载 / 软件源 |
| 5 | 配置Docker | 安装 + Compose + 镜像加速 |
| 6 | 配置Vulfocus | 漏洞集成平台 |
| 7 | 配置ARL灯塔 | 资产侦察灯塔 |
| 8 | 配置Metasploit | 渗透测试框架 |
| 9 | 配置Viper | 图形化渗透平台 |
| 10 | 配置Empire | 后渗透框架 |
| 11 | 配置Dnscat2 | DNS 隧道 |
| 12 | 配置BeEF | 浏览器渗透框架 |
| 13 | 配置BlueLotus | XSS 平台 |
| 14 | 配置HFish | 蜜罐系统 |
| 15 | 配置CTFd | CTF 竞赛平台 |
| 16 | 配置AWVS | Web 漏洞扫描器 |
| 17 | 配置OCR-API | OCR 识别服务 |
| 18 | 配置OhMyZsh | Zsh 增强（Gitee 镜像） |
| 19 | 配置crAPI | 现代 API 靶场 |
| 20 | 配置XingRin | XingRin 平台 |
| 21 | 配置DeepAudit | 深度审计 |
| 22 | 配置ScopeSentry | 资产测绘 |
| 23 | 系统优化 | 时区 / BBR 性能优化 / SSH 安全加固（新增） |

## 安装与使用

```bash
git clone https://github.com/Daiyq-hub/linux-env-helper.git
cd linux-env-helper
sudo bash install.sh          # 注册全局命令 leh
leh                           # 任意目录启动
```

也可以不安装，直接运行：

```bash
sudo bash main.sh
```

## 与上游 LinuxEnvConfig 的差异

- 新增「系统优化」模块：时区设置、BBR 内核参数优化、SSH 安全加固（fail2ban / 改端口 / 禁用密码登录，带防锁死检查）
- JDK 模块新增「公共镜像/官网（免密钥）」安装源：JDK 8 走华为云镜像，11/17/21/22/23 走 Oracle 官网 NFTC 下载；教学平台密钥仍作为可选项保留
- 安装命令注册为 `leh`，避免与 LinuxEnvConfig 的 `lec` 冲突
- 修复 install.sh 可执行权限问题（仓库内以 755 提交）
- 不包含上游仓库的截图等素材文件，仅保留代码与文档；上游完整内容请访问原仓库

## 适用系统

Ubuntu 18.04+ / Debian 10+（apt 系），Kali Linux 亦可运行部分模块。

## License

Apache License 2.0。上游代码版权归湖南蚁景科技有限公司及其作者 mingy 所有，本仓库保留原始版权声明与 LICENSE 文件。
