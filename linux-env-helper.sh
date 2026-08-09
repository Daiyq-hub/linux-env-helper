#!/usr/bin/env bash
# ============================================================================
#  LinuxEnv Helper v1.0  ——  Linux 环境配置助手
# ----------------------------------------------------------------------------
#  面向国内网络环境的 Ubuntu/Debian 服务器一键配置脚本（交互式菜单）
#
#  灵感与实现参考的开源项目：
#    - plutobe/linux-init-cn.sh      系统初始化、Docker 国内镜像加速
#    - qfpqhyl/server-scripts        Miniconda/Python、性能优化、换源
#    - butlanys/code.sh              交互式菜单与命令行参数风格
#    - vulhub/vulhub、fofapro/vulfocus、CTFd  漏洞靶场部署
#    - LinuxEnvConfig (yijingsec)    菜单交互与模块化组织思路
#
#  适用系统: Ubuntu 18.04+ / Debian 10+  (apt 系)
#  使用方法: sudo bash linux-env-helper.sh
# ============================================================================

set -u

# ─────────────────────────────────────────────────────────────
# 颜色与消息函数
# ─────────────────────────────────────────────────────────────
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
BLUE=$'\033[34m'; CYAN=$'\033[36m'; WHITE=$'\033[37m'
BOLD=$'\033[1m'; NC=$'\033[0m'

msg_info()  { echo -e "  ${BLUE}[INFO]${NC} $1"; }
msg_ok()    { echo -e "  ${GREEN}[ OK ]${NC} $1"; }
msg_warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
msg_fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; }

section() {
    echo ""
    echo -e "  ${BOLD}${CYAN}▸ $1${NC}"
    echo -e "  ${CYAN}────────────────────────────────────────────────────────${NC}"
}

confirm() {
    local prompt="${1:-确认执行此操作?}"
    local resp
    while true; do
        read -r -p "  [ ?? ] ${prompt} [y/N]: " resp
        case "$resp" in
            [Yy]*) return 0 ;;
            [Nn]*|"") return 1 ;;
            *) msg_warn "请输入 y 或 n" ;;
        esac
    done
}

pause() {
    echo ""
    read -r -n 1 -p "  按任意键继续..." 
    echo ""
}

# ─────────────────────────────────────────────────────────────
# 基础环境检测
# ─────────────────────────────────────────────────────────────
require_root() {
    if [[ $EUID -ne 0 ]]; then
        msg_fail "必须使用 sudo 或 root 权限运行"
        exit 1
    fi
}

DISTRO_ID=""
DISTRO_CODENAME=""
detect_os() {
    if [[ -f /etc/os-release ]]; then
        DISTRO_ID=$(. /etc/os-release; echo "${ID:-unknown}")
        DISTRO_CODENAME=$(. /etc/os-release; echo "${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}")
    fi
    if [[ "$DISTRO_ID" != "ubuntu" && "$DISTRO_ID" != "debian" ]]; then
        msg_warn "当前发行版: ${DISTRO_ID:-unknown}，本脚本主要针对 Ubuntu/Debian 测试"
    fi
    msg_info "检测到系统: ${DISTRO_ID:-unknown} ${DISTRO_CODENAME:-unknown}"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ─────────────────────────────────────────────────────────────
# 模块 1: 系统信息
# ─────────────────────────────────────────────────────────────
show_system_info() {
    section "系统信息"
    echo "  操作系统 : $(. /etc/os-release; echo "$PRETTY_NAME")"
    echo "  内核版本 : $(uname -r)"
    echo "  主机架构 : $(uname -m)"
    echo "  内存     : $(free -h | awk '/^Mem:/{print $2 " (可用 " $7 ")"}')"
    echo "  磁盘     : $(df -h / | awk 'NR==2{print $3 " 已用 / " $2 " (" $5 ")"}')"
    echo "  本机 IP  : $(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -1)"
    echo ""
    echo "  已安装 JDK:"
    if [[ -d /usr/lib/jvm ]]; then
        for d in /usr/lib/jvm/*/; do
            [[ -x "${d}bin/java" ]] && echo "    - ${d} ($("${d}bin/java" -version 2>&1 | head -1))"
        done
    else
        echo "    （未检测到）"
    fi
    echo ""
    echo "  Docker: $(command_exists docker && docker --version 2>/dev/null || echo 未安装)"
    echo "  Miniconda: $(command_exists conda && conda --version 2>/dev/null || echo 未安装)"
    pause
}

# ─────────────────────────────────────────────────────────────
# 模块 2: 系统初始化（时区 / 基础工具 / APT 源）
# ─────────────────────────────────────────────────────────────
set_timezone() {
    section "设置时区"
    timedatectl set-timezone Asia/Shanghai 2>/dev/null \
        || ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    msg_ok "时区已设置为 Asia/Shanghai ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
}

install_basic_tools() {
    section "安装基础工具"
    local tools=(curl wget git vim unzip tar htop iotop net-tools dnsutils jq ca-certificates gnupg lsb-release)
    msg_info "安装: ${tools[*]}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${tools[@]}" || {
        msg_fail "安装基础工具失败，请先确认 APT 源可用"
        return 1
    }
    msg_ok "基础工具安装完成"
}

setup_apt_mirror() {
    section "切换 APT 源"
    [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" ]] || {
        msg_warn "仅支持 Ubuntu/Debian 自动换源"
        return 1
    }
    [[ -n "$DISTRO_CODENAME" ]] || {
        msg_warn "无法识别系统版本代号，跳过换源"
        return 1
    }

    echo ""
    echo "  请选择镜像源:"
    echo "    1) 腾讯云     (mirrors.cloud.tencent.com)"
    echo "    2) 阿里云     (mirrors.aliyun.com)"
    echo "    3) 清华大学   (mirrors.tuna.tsinghua.edu.cn)"
    echo "    4) 中科大     (mirrors.ustc.edu.cn)"
    echo "    0) 跳过"
    read -r -p "  ➤ 请输入序号 [0-4]: " src

    local mirror_url=""
    case "$src" in
        1) mirror_url="https://mirrors.cloud.tencent.com" ;;
        2) mirror_url="https://mirrors.aliyun.com" ;;
        3) mirror_url="https://mirrors.tuna.tsinghua.edu.cn" ;;
        4) mirror_url="https://mirrors.ustc.edu.cn" ;;
        *) msg_info "跳过 APT 源配置"; return 0 ;;
    esac

    local sources_list="/etc/apt/sources.list"
    local bak="${sources_list}.bak.$(date +%Y%m%d_%H%M%S)"
    if [[ -f "$sources_list" ]]; then
        cp -a "$sources_list" "$bak"
        msg_info "已备份: $bak"
    fi

    if [[ "$DISTRO_ID" == "ubuntu" ]]; then
        cat > "$sources_list" << EOF
deb ${mirror_url}/ubuntu ${DISTRO_CODENAME} main restricted universe multiverse
deb ${mirror_url}/ubuntu ${DISTRO_CODENAME}-updates main restricted universe multiverse
deb ${mirror_url}/ubuntu ${DISTRO_CODENAME}-backports main restricted universe multiverse
deb ${mirror_url}/ubuntu ${DISTRO_CODENAME}-security main restricted universe multiverse
EOF
    else
        cat > "$sources_list" << EOF
deb ${mirror_url}/debian ${DISTRO_CODENAME} main contrib non-free non-free-firmware
deb ${mirror_url}/debian ${DISTRO_CODENAME}-updates main contrib non-free non-free-firmware
deb ${mirror_url}/debian ${DISTRO_CODENAME}-backports main contrib non-free non-free-firmware
deb ${mirror_url}/debian-security ${DISTRO_CODENAME}-security main contrib non-free non-free-firmware
EOF
    fi

    msg_info "正在更新软件包索引 (首次可能较慢)..."
    apt-get update || msg_warn "apt-get update 失败，可检查网络或换其他源"
    msg_ok "APT 源配置完成 (${mirror_url})"
}

init_system() {
    msg_info "开始系统初始化..."
    set_timezone
    install_basic_tools
    if confirm "是否切换 APT 国内镜像源?"; then
        setup_apt_mirror
    else
        msg_info "跳过 APT 源配置"
    fi
    pause
}

# ─────────────────────────────────────────────────────────────
# 模块 3: Docker + Compose + 国内镜像加速
# ─────────────────────────────────────────────────────────────
install_docker() {
    section "安装 Docker"
    if command_exists docker; then
        msg_ok "Docker 已安装: $(docker --version)"
        configure_docker_mirror
        return 0
    fi

    [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" ]] || {
        msg_fail "自动安装 Docker 仅支持 Ubuntu/Debian"
        return 1
    }

    local mirror="https://mirrors.cloud.tencent.com"
    msg_info "使用腾讯云 Docker 源: ${mirror}/docker-ce"

    apt-get update -y >/dev/null 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl gnupg lsb-release || {
        msg_fail "安装 Docker 依赖失败"
        return 1
    }

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "${mirror}/docker-ce/linux/${DISTRO_ID}/gpg" \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] ${mirror}/docker-ce/linux/${DISTRO_ID} ${DISTRO_CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list

    apt-get update -y || { msg_fail "Docker 源更新失败"; return 1; }
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
        msg_fail "Docker 安装失败"
        return 1
    }

    systemctl enable --now docker >/dev/null 2>&1
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER" 2>/dev/null && \
            msg_info "已将用户 ${SUDO_USER} 加入 docker 组（重新登录后免 sudo 生效）"
    fi
    msg_ok "Docker 安装完成: $(docker --version)"
    msg_ok "Compose 插件: $(docker compose version)"
    configure_docker_mirror
}

configure_docker_mirror() {
    section "配置 Docker 国内镜像加速"
    local daemon="/etc/docker/daemon.json"
    mkdir -p /etc/docker
    cat > "$daemon" << 'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.cattt.net",
    "https://docker.m.ixdev.cn",
    "https://hub.mirrorify.net",
    "https://2a6bf1988cb6428c877f723ec7530dbc.mirror.swr.myhuaweicloud.com"
  ]
}
EOF
    systemctl restart docker 2>/dev/null
    msg_ok "Docker 镜像加速已配置并重启服务"
}

# ─────────────────────────────────────────────────────────────
# 模块 4: Miniconda3 + 国内源
# ─────────────────────────────────────────────────────────────
install_miniconda() {
    section "安装 Miniconda3"
    if command_exists conda; then
        msg_ok "Miniconda 已安装: $(conda --version)"
        configure_conda_mirror
        return 0
    fi

    local target_user="${SUDO_USER:-root}"
    local home_dir
    if [[ "$target_user" == "root" ]]; then
        home_dir="/root"
    else
        home_dir="$(getent passwd "$target_user" | cut -d: -f6)"
    fi
    local install_dir="${CONDA_DIR:-${home_dir}/miniconda3}"

    local installer="/tmp/Miniconda3-latest-Linux-x86_64.sh"
    msg_info "从清华镜像下载 Miniconda3..."
    if ! curl -fsSL -o "$installer" \
        "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"; then
        msg_warn "清华镜像下载失败，改用官方源"
        curl -fsSL -o "$installer" \
            "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" || {
            msg_fail "Miniconda 下载失败"
            return 1
        }
    fi

    msg_info "安装到 $install_dir"
    bash "$installer" -b -p "$install_dir"
    rm -f "$installer"

    if [[ "$target_user" != "root" ]]; then
        chown -R "$target_user":"$(id -gn "$target_user")" "$install_dir"
    fi
    "$install_dir/bin/conda" init bash
    msg_info "已写入 shell 初始化配置（重新登录后 conda 生效）"
    msg_ok "Miniconda 安装完成: $("$install_dir/bin/conda" --version)"
    configure_conda_mirror
}

configure_conda_mirror() {
    section "配置 conda / pip 国内源"
    local conda_bin
    conda_bin="$(command -v conda || echo "$HOME/miniconda3/bin/conda")"
    local target_user="${SUDO_USER:-root}"
    local home_dir="${target_user:+$(getent passwd "$target_user" | cut -d: -f6)}"
    home_dir="${home_dir:-$HOME}"

    cat > "$home_dir/.condarc" << 'EOF'
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
EOF

    mkdir -p "$home_dir/.pip"
    cat > "$home_dir/.pip/pip.conf" << 'EOF'
[global]
index-url = https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
trusted-host = mirrors.tuna.tsinghua.edu.cn
EOF

    chown -R "$target_user":"$(id -gn "$target_user")" "$home_dir/.condarc" "$home_dir/.pip" 2>/dev/null
    msg_ok "conda 与 pip 国内源配置完成"
}

# ─────────────────────────────────────────────────────────────
# 模块 5: JDK 安装与管理
# ─────────────────────────────────────────────────────────────
list_jdks() {
    echo ""
    if [[ -d /usr/lib/jvm ]]; then
        local found=false
        for d in /usr/lib/jvm/*/; do
            if [[ -x "${d}bin/java" ]]; then
                found=true
                echo "  - ${d}  ($("${d}bin/java" -version 2>&1 | head -1))"
            fi
        done
        [[ "$found" == true ]] || echo "  （未检测到 JDK）"
    else
        echo "  （未检测到 JDK）"
    fi
}

install_oracle_jdk8() {
    section "安装 Oracle JDK 8 (8u202)"
    local url="https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz"
    local pkg="/tmp/jdk-8u202-linux-x64.tar.gz"
    local target="/usr/lib/jvm/jdk1.8.0_202"

    [[ -x "$target/bin/java" ]] && {
        msg_ok "JDK 8 已存在: $("$target/bin/java" -version 2>&1 | head -1)"
        return 0
    }

    msg_info "从华为云镜像下载 (~194MB)..."
    curl -fsSL -o "$pkg" "$url" || { msg_fail "下载失败"; return 1; }
    mkdir -p /usr/lib/jvm
    tar -xzf "$pkg" -C /usr/lib/jvm
    rm -f "$pkg"

    for b in java javac keytool jar jarsigner; do
        if [[ -x "$target/bin/$b" ]]; then
            update-alternatives --install "/usr/bin/$b" "$b" "$target/bin/$b" 100 >/dev/null 2>&1
            update-alternatives --set "$b" "$target/bin/$b" >/dev/null 2>&1
        fi
    done

    cat > /etc/profile.d/jdk.sh << 'EOF'
if [ -x /usr/bin/java ]; then
    export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
    export CLASSPATH=.:$JAVA_HOME/lib
fi
EOF
    msg_ok "Oracle JDK 8 安装完成: $("$target/bin/java" -version 2>&1 | head -1)"
}

install_openjdk_apt() {
    local ver="$1"
    section "通过 APT 安装 OpenJDK ${ver}"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "openjdk-${ver}-jdk" || {
        msg_fail "安装失败（当前系统可能没有 openjdk-${ver} 包）"
        return 1
    }
    msg_ok "OpenJDK ${ver} 安装完成"
}

manage_jdk() {
    while true; do
        section "JDK 安装与管理"
        list_jdks
        echo ""
        echo "  请选择操作:"
        echo "    1) 安装 Oracle JDK 8  (华为云镜像, 免密钥)"
        echo "    2) 安装 OpenJDK 17   (apt)"
        echo "    3) 安装 OpenJDK 8    (apt)"
        echo "    0) 返回主菜单"
        read -r -p "  ➤ 请输入序号 [0-3]: " choice
        case "$choice" in
            1) install_oracle_jdk8 ;;
            2) install_openjdk_apt 17 ;;
            3) install_openjdk_apt 8 ;;
            0) return ;;
            *) msg_warn "无效选择" ;;
        esac
        pause
    done
}

# ─────────────────────────────────────────────────────────────
# 模块 6: SSH 安全加固（可选，注意勿锁死自己）
# ─────────────────────────────────────────────────────────────
install_fail2ban() {
    section "安装 fail2ban"
    DEBIAN_FRONTEND=noninteractive apt-get install -y fail2ban || {
        msg_fail "fail2ban 安装失败"
        return 1
    }
    cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
maxretry = 5
bantime = 3600
EOF
    systemctl enable --now fail2ban >/dev/null 2>&1
    msg_ok "fail2ban 已启用 (SSH 连续失败 5 次封禁 1 小时)"
}

change_ssh_port() {
    section "修改 SSH 端口"
    read -r -p "  请输入新端口 (例如 2222): " new_port
    [[ "$new_port" =~ ^[0-9]+$ ]] && [[ $new_port -ge 1024 && $new_port -le 65535 ]] || {
        msg_fail "端口无效"
        return 1
    }
    if confirm "确定将 SSH 端口改为 ${new_port}? 请确保防火墙已放行，否则可能断开连接"; then
        sed -i "s/^#\?Port .*/Port ${new_port}/" /etc/ssh/sshd_config
        systemctl restart sshd
        msg_ok "SSH 端口已改为 ${new_port}（当前连接不会断开）"
        msg_warn "请立即用新端口测试连接: ssh -p ${new_port} user@server"
    fi
}

disable_ssh_password() {
    section "禁用 SSH 密码登录（仅密钥）"
    local user="${SUDO_USER:-root}"
    local key_file="${user:+$(getent passwd "$user" | cut -d: -f6)}/.ssh/authorized_keys"
    if [[ ! -s "$key_file" ]]; then
        msg_fail "未检测到 ${user} 的 SSH 公钥 ($key_file)，为避免锁死已取消"
        return 1
    fi
    if confirm "确定禁用密码登录? 请确认你已能用密钥连接，否则会失联"; then
        sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
        systemctl restart sshd
        msg_ok "已禁用密码登录（仅允许密钥）"
        msg_warn "请先开新会话验证，再关闭当前窗口"
    fi
}

ssh_hardening() {
    while true; do
        section "SSH 安全加固（可选）"
        echo "  请选择操作:"
        echo "    1) 安装 fail2ban（SSH 防暴力破解，推荐且安全）"
        echo "    2) 修改 SSH 端口（有断连风险）"
        echo "    3) 禁用密码登录仅密钥（有锁死风险）"
        echo "    0) 返回主菜单"
        read -r -p "  ➤ 请输入序号 [0-3]: " choice
        case "$choice" in
            1) install_fail2ban ;;
            2) change_ssh_port ;;
            3) disable_ssh_password ;;
            0) return ;;
            *) msg_warn "无效选择" ;;
        esac
        pause
    done
}

# ─────────────────────────────────────────────────────────────
# 模块 7: 系统性能优化（BBR 等）
# ─────────────────────────────────────────────────────────────
optimize_system() {
    section "系统性能优化"
    local sysctl_file="/etc/sysctl.d/99-envhelper.conf"
    [[ -f "$sysctl_file" ]] && cp -a "$sysctl_file" "${sysctl_file}.bak.$(date +%Y%m%d_%H%M%S)"

    cat > "$sysctl_file" << 'EOF'
# BBR 拥塞控制
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
# 网络缓冲区与连接队列
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fastopen = 3
# TIME_WAIT 复用
net.ipv4.tcp_tw_reuse = 1
# 文件描述符限制
fs.file-max = 2097152
EOF

    sysctl --system >/dev/null 2>&1
    local cur
    cur=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    msg_ok "配置完成，当前拥塞控制算法: ${cur:-未知}（应为 bbr）"
    grep -q "ENVHELPER" /etc/security/limits.conf || {
        echo "# ENVHELPER" >> /etc/security/limits.conf
        echo "* soft nofile 1048576" >> /etc/security/limits.conf
        echo "* hard nofile 1048576" >> /etc/security/limits.conf
    }
    pause
}

# ─────────────────────────────────────────────────────────────
# 模块 8: 漏洞靶场部署（需要 Docker）
# ─────────────────────────────────────────────────────────────
deploy_vulhub() {
    section "部署 Vulhub 漏洞靶场"
    local dir="/opt/vulhub"
    if [[ -d "$dir/.git" ]]; then
        msg_info "Vulhub 已存在，执行更新"
        git -C "$dir" pull --quiet
    else
        msg_info "从 GitHub 克隆 vulhub (约 1GB，国内网络可能较慢)..."
        if ! git clone --depth 1 https://github.com/vulhub/vulhub.git "$dir"; then
            msg_warn "GitHub 克隆失败，尝试 Gitee 镜像"
            git clone --depth 1 https://gitee.com/mirrors/vulhub.git "$dir" || {
                msg_fail "克隆失败，请检查网络"
                return 1
            }
        fi
    fi
    msg_ok "Vulhub 已就绪: $dir"
    msg_info "使用方式: cd $dir/<漏洞目录> && docker compose up -d"
}

deploy_vulfocus() {
    section "部署 Vulfocus 漏洞平台"
    command_exists docker || { msg_fail "请先安装 Docker"; return 1; }
    read -r -p "  请输入映射端口 [默认 5000]: " port
    port="${port:-5000}"
    docker rm -f vulfocus >/dev/null 2>&1
    docker run -d --name vulfocus \
        -p "${port}:5000" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        vulfocus/vulfocus:latest
    msg_ok "Vulfocus 已启动: http://$(hostname -I | awk '{print $1}'):${port}"
    msg_info "默认账号: admin / admin"
}

deploy_ctfd() {
    section "部署 CTFd 竞赛平台"
    command_exists docker || { msg_fail "请先安装 Docker"; return 1; }
    read -r -p "  请输入映射端口 [默认 8000]: " port
    port="${port:-8000}"
    docker rm -f ctfd >/dev/null 2>&1
    docker run -d --name ctfd -p "${port}:8000" ctfd/ctfd:latest
    msg_ok "CTFd 已启动: http://$(hostname -I | awk '{print $1}'):${port}"
}

deploy_labs() {
    while true; do
        section "漏洞靶场部署"
        echo "  请选择操作:"
        echo "    1) 部署 Vulhub（Docker 漏洞环境集，需 Docker）"
        echo "    2) 部署 Vulfocus（漏洞集成平台）"
        echo "    3) 部署 CTFd（CTF 竞赛平台）"
        echo "    0) 返回主菜单"
        read -r -p "  ➤ 请输入序号 [0-3]: " choice
        case "$choice" in
            1) deploy_vulhub ;;
            2) deploy_vulfocus ;;
            3) deploy_ctfd ;;
            0) return ;;
            *) msg_warn "无效选择" ;;
        esac
        pause
    done
}

# ─────────────────────────────────────────────────────────────
# 模块 9: Oh My Zsh
# ─────────────────────────────────────────────────────────────
install_ohmyzsh() {
    section "安装 Oh My Zsh"
    DEBIAN_FRONTEND=noninteractive apt-get install -y zsh curl git >/dev/null 2>&1
    if [[ -d "${SUDO_USER:+$(getent passwd "$SUDO_USER" | cut -d: -f6)}/.oh-my-zsh" ]]; then
        msg_ok "Oh My Zsh 已安装，跳过"
    else
        local target_user="${SUDO_USER:-root}"
        msg_info "通过 Gitee 镜像安装 Oh My Zsh..."
        su - "$target_user" -c \
            'sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)" "" --unattended' \
            || {
                msg_warn "Gitee 安装失败，改用 GitHub"
                su - "$target_user" -c \
                    'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
            }
    fi
    chsh -s "$(command -v zsh)" "${SUDO_USER:-root}" 2>/dev/null
    msg_ok "Oh My Zsh 安装完成，重新登录后生效"
    pause
}

# ─────────────────────────────────────────────────────────────
# 主菜单
# ─────────────────────────────────────────────────────────────
show_menu() {
    echo ""
    echo -e "  ${BOLD}${GREEN}╭──────────────────────────────────────────────╮${NC}"
    echo -e "  ${BOLD}${GREEN}│        LinuxEnv Helper v1.0                   │${NC}"
    echo -e "  ${BOLD}${GREEN}│        Linux 环境配置助手（Ubuntu/Debian）    │${NC}"
    echo -e "  ${BOLD}${GREEN}╰──────────────────────────────────────────────╯${NC}"
    echo ""
    echo "    1. 查看系统信息"
    echo "    2. 系统初始化（时区/基础工具/APT源）"
    echo "    3. 安装 Docker + Compose（含国内加速）"
    echo "    4. 安装 Miniconda3（含国内源）"
    echo "    5. JDK 安装与管理"
    echo "    6. SSH 安全加固（可选）"
    echo "    7. 系统性能优化（BBR）"
    echo "    8. 漏洞靶场部署（Vulhub/Vulfocus/CTFd）"
    echo "    9. 安装 Oh My Zsh"
    echo "    0. 退出"
}

main() {
    require_root
    detect_os

    while true; do
        show_menu
        read -r -p "  ➤ 请输入序号 [0-9]: " choice
        case "$choice" in
            1) show_system_info ;;
            2) init_system ;;
            3) install_docker ;;
            4) install_miniconda ;;
            5) manage_jdk ;;
            6) ssh_hardening ;;
            7) optimize_system ;;
            8) deploy_labs ;;
            9) install_ohmyzsh ;;
            0)
                echo -e "\n  感谢使用，再见 👋\n"
                exit 0
                ;;
            *) msg_warn "无效选择" ;;
        esac
    done
}

main "$@"
