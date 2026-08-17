#!/usr/bin/env bash
#
# LinuxEnv Helper - info.sh (系统信息)
# License: Apache License 2.0

# ═══════════════════════════════════════════════════════════════
# 查看系统环境信息（只读，适合新VPS首次检查）
# ═══════════════════════════════════════════════════════════════

config_info() {
    show_section "系统环境信息"
    show_system_info
    echo ""
    pause
}

show_system_info() {
    local widths="16 42"
    msg_table_row "$widths" "${BOLD}项目" "内容${NC}"
    draw_line "-"

    local os kernel uptime cpu load mem swap disk local_ip pub_ip
    local docker_v compose_v py_v java_v containers ports sec

    os="$(get_os_name) $(get_os_ver) ($(get_distro_id))"
    kernel="$(uname -r)"
    uptime="$(uptime -p 2>/dev/null | sed 's/up //')"
    cpu="$(nproc) 核 $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | sed 's/.*: //')"
    load="$(awk '{print $1", "$2", "$3}' /proc/loadavg) (1/5/15分钟)"
    mem="$(LC_ALL=C free -h | awk '/^Mem:/{print $3" / "$2}')"
    swap="$(LC_ALL=C free -h | awk '/^Swap:/{print $3" / "$2}')"
    disk="$(df -h / | awk 'NR==2{print $3" / "$2" ("$5" 已用)"}')"
    local_ip="$(get_local_ip)"
    pub_ip="$(get_public_ip || echo 无法获取)"
    docker_v="$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
    compose_v="$(docker compose version 2>/dev/null | awk '{print $4}' || docker-compose --version 2>/dev/null)"
    py_v="$(python3 --version 2>/dev/null)"
    java_v="$(java -version 2>&1 | head -1)"

    msg_table_row "$widths" "操作系统" "${os}"
    msg_table_row "$widths" "内核版本" "${kernel}"
    msg_table_row "$widths" "运行时长" "${uptime}"
    msg_table_row "$widths" "CPU" "${cpu}"
    msg_table_row "$widths" "负载" "${load}"
    msg_table_row "$widths" "内存(已用/总)" "${mem}"
    msg_table_row "$widths" "交换分区" "${swap}"
    msg_table_row "$widths" "磁盘(已用/总)" "${disk}"
    msg_table_row "$widths" "内网IP" "${local_ip}"
    msg_table_row "$widths" "公网IP" "${pub_ip}"
    msg_table_row "$widths" "Docker" "${docker_v:-未安装}"
    msg_table_row "$widths" "Compose" "${compose_v:-未安装}"
    msg_table_row "$widths" "Python3" "${py_v:-未安装}"
    msg_table_row "$widths" "Java" "${java_v:-未安装}"

    containers=$(docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')
    msg_table_row "$widths" "运行容器" "${containers:-无}"

    ports=$(ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | sed 's/.*://' | sort -n | uniq | tr '\n' ' ')
    msg_table_row "$widths" "监听端口" "${ports:0:100}"

    sec=""
    if is_service_active fail2ban; then sec+="fail2ban:运行中 "; else sec+="fail2ban:未启用 "; fi
    if ufw status 2>/dev/null | grep -q "Status: active"; then sec+="ufw:已启用"; else sec+="ufw:未启用"; fi
    msg_table_row "$widths" "安全状态" "${sec}"
}

register_main_menu "查看系统信息" "config_info"
