# LinuxEnv Helper

Linux 环境配置助手 —— 面向国内网络环境的 Ubuntu/Debian 服务器一键配置脚本（交互式菜单）。

## 功能

- 查看系统信息（OS / 内存 / 磁盘 / JDK / Docker 状态）
- 系统初始化：时区、基础工具、APT 国内源（腾讯 / 阿里 / 清华 / 中科大，自动备份）
- Docker + Compose 安装（腾讯云源），含国内镜像加速配置
- Miniconda3 安装（清华镜像）+ conda / pip 换源
- JDK 管理：Oracle JDK 8（华为云镜像，免密钥）/ OpenJDK 8、17（apt），自动识别已装版本
- SSH 安全加固（可选）：fail2ban / 修改端口 / 禁用密码登录（带防锁死保护）
- 系统性能优化：BBR 拥塞控制 + sysctl 调优（自动备份）
- 漏洞靶场部署：Vulhub / Vulfocus / CTFd
- 安装 Oh My Zsh（Gitee 镜像）

## 使用方法

```bash
sudo bash linux-env-helper.sh
```

按数字选择模块即可，每个模块都有确认提示与自动备份。

## 适用系统

Ubuntu 18.04+ / Debian 10+（apt 系）

## 参考的开源项目

- [plutobe/linux-init-cn.sh](https://github.com/plutobe/linux-init-cn.sh)
- [qfpqhyl/server-scripts](https://github.com/qfpqhyl/server-scripts)
- [butlanys/code.sh](https://github.com/butlanys/code.sh)
- [vulhub/vulhub](https://github.com/vulhub/vulhub)
- [fofapro/vulfocus](https://github.com/fofapro/vulfocus)
- [CTFd/CTFd](https://github.com/CTFd/CTFd)
- [yijingsec/LinuxEnvConfig](https://gitee.com/yijingsec/LinuxEnvConfig)
