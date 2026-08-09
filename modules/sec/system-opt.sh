#!/usr/bin/env bash
#
# Copyright 2026 LinuxEnv Helper contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  📝 模块描述 : 系统优化模块 (时区 / 性能 / SSH安全加固)
#  📁 文件路径 : modules/system-opt.sh
#  📌 说明     : LinuxEnv Helper 新增模块
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


# ═══════════════════════════════════════════════════════════════
# 系统优化主菜单
# ═══════════════════════════════════════════════════════════════

config_system_opt() {
    while true; do
        show_submenu "系统优化" \
            "设置时区(Asia/Shanghai)" \
            "系统性能优化(BBR)" \
            "SSH安全加固"

        local choice
        msg_prompt "请选择操作 [0-3, q退出]"

        case $choice in
            0) return ;;
            q|Q) exit 0 ;;
            1) set_timezone_cn ;;
            2) push_path "性能优化"; optimize_sysctl_cn; pop_path; continue ;;
            3) push_path "SSH加固"; ssh_harden_cn; pop_path; continue ;;
            *) msg_error "无效选择" ;;
        esac

        pause
    done
}

# ═══════════════════════════════════════════════════════════════
# 时区设置
# ═══════════════════════════════════════════════════════════════

set_timezone_cn() {
    show_section "设置时区"
    if timedatectl set-timezone Asia/Shanghai 2>/dev/null \
        || ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; then
        msg_success "时区已设置为 Asia/Shanghai ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
    else
        msg_error "设置时区失败"
    fi
}

# ═══════════════════════════════════════════════════════════════
# 系统性能优化（BBR 等）
# ═══════════════════════════════════════════════════════════════

optimize_sysctl_cn() {
    show_section "系统性能优化 (BBR)"

    local sysctl_file="/etc/sysctl.d/99-envhelper.conf"
    backup_file "$sysctl_file" || true

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

    modprobe tcp_bbr 2>/dev/null || true
    sysctl --system >/dev/null 2>&1 || true

    local cur
    cur=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [[ "$cur" == "bbr" ]]; then
        msg_success "BBR 已启用 (当前算法: $cur)"
    else
        msg_warning "BBR 未生效 (当前: ${cur:-未知})，可能需要重启生效"
    fi
    msg_info "当前进程文件描述符上限: $(ulimit -n)"
}

# ═══════════════════════════════════════════════════════════════
# SSH 安全加固
# ═══════════════════════════════════════════════════════════════

ssh_harden_cn() {
    while true; do
        show_submenu "SSH安全加固" \
            "安装fail2ban (推荐)" \
            "修改SSH端口" \
            "禁用密码登录(仅密钥)"

        local choice
        msg_prompt "请选择操作 [0-3, q退出]"

        case $choice in
            0) return ;;
            q|Q) exit 0 ;;
            1) install_fail2ban_cn ;;
            2) change_ssh_port_cn ;;
            3) disable_ssh_pwd_cn ;;
            *) msg_error "无效选择" ;;
        esac
        pause
    done
}

install_fail2ban_cn() {
    show_section "安装 fail2ban"
    if ! install_package fail2ban; then
        msg_error "fail2ban 安装失败"
        return 1
    fi

    cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
maxretry = 5
bantime = 3600
EOF

    enable_service fail2ban || true
    start_service fail2ban || true
    msg_success "fail2ban 已启用 (SSH 连续失败 5 次封禁 1 小时)"
}

change_ssh_port_cn() {
    show_section "修改 SSH 端口"

    local new_port
    msg_prompt "请输入新端口 (1024-65535, 例如 2222)" "new_port"
    if [[ ! "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1024 || new_port > 65535 )); then
        msg_error "端口无效"
        return 1
    fi

    if ! confirm "确定将 SSH 端口改为 ${new_port}? 请确认防火墙已放行该端口"; then
        return 1
    fi

    backup_file /etc/ssh/sshd_config
    if grep -qE "^#?Port\s" /etc/ssh/sshd_config; then
        sed -i -E "s/^#?Port\s+.*/Port ${new_port}/" /etc/ssh/sshd_config
    else
        echo "Port ${new_port}" >> /etc/ssh/sshd_config
    fi

    restart_service ssh
    msg_success "SSH 端口已改为 ${new_port}（当前连接不会断开）"
    msg_warning "请立即用新端口测试: ssh -p ${new_port} user@server"
}

disable_ssh_pwd_cn() {
    show_section "禁用 SSH 密码登录（仅密钥）"

    local user="${SUDO_USER:-root}"
    local key_file
    if [[ "$user" == "root" ]]; then
        key_file="/root/.ssh/authorized_keys"
    else
        key_file="$(getent passwd "$user" | cut -d: -f6)/.ssh/authorized_keys"
    fi

    if [[ ! -s "$key_file" ]]; then
        msg_error "未检测到 ${user} 的 SSH 公钥 (${key_file})，为避免锁死已取消"
        return 1
    fi

    if ! confirm "确定禁用密码登录? 请确认你已能用密钥连接，否则会失联"; then
        return 1
    fi

    backup_file /etc/ssh/sshd_config
    if grep -qE "^#?PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i -E 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    else
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi
    if grep -qE "^#?PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i -E 's/^#?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
    fi

    restart_service ssh
    msg_success "已禁用密码登录（仅允许密钥）"
    msg_warning "请先开新会话验证，再关闭当前窗口"
}

register_main_menu "系统优化" "config_system_opt"
