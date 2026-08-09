#!/usr/bin/env bash
#
# LinuxEnv Helper - core.sh
# License: Apache License 2.0

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


# ═══════════════════════════════════════════════════════════════
# 全局状态变量定义
# ═══════════════════════════════════════════════════════════════

OS_ID=""
OS_CODENAME=""
OS_NAME=""
OS_VER=""

# ═══════════════════════════════════════════════════════════════
# 运行环境检查
# ═══════════════════════════════════════════════════════════════

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        msg_error "请使用root用户或sudo运行此脚本"
        exit 1
    fi
}

check_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        
        OS_ID="$ID"
        OS_CODENAME="${VERSION_CODENAME:-}"
        OS_NAME="$NAME"
        OS_VER="${VERSION_ID:-}"
        
        export OS_ID OS_CODENAME OS_NAME OS_VER
        
        case "$OS_ID" in
            ubuntu|kali|debian)
                return 0
                ;;
            *)
                msg_error "本脚本仅适用于 Ubuntu / Kali / Debian 系统"
                exit 1
                ;;
        esac
    else
        msg_error "无法检测操作系统"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# 系统信息查询
# ═══════════════════════════════════════════════════════════════

get_distro_id() { echo "${OS_ID:-unknown}"; }
get_distro_codename() { echo "${OS_CODENAME:-unknown}"; }
get_os_name() { echo "${OS_NAME:-Unknown}"; }
get_os_ver() { echo "${OS_VER:-Unknown}"; }
